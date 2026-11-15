// Sauti hybrid inference bridge.
//
// On-device first: Apple Foundation Models (`SystemLanguageModel`, iOS 26+).
// Cloud fallback: Gemini through Firebase AI Logic (`GeminiLanguageModel`,
// iOS 27+), used inside the same Apple `LanguageModelSession`.
//
// The session drives the tool loop itself. Every tool call is forwarded to
// Dart (`executeTool`), where Sauti's permissioned ToolRegistry validates and
// runs it. No banking logic lives in Swift.

import Flutter
import Foundation

#if canImport(FoundationModels)
  import FoundationModels
#endif

#if canImport(FirebaseAILogic)
  import FirebaseAILogic
  import FirebaseCore
#endif

public final class SautiHybridAiPlugin: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "sauti/hybrid_ai", binaryMessenger: registrar.messenger())
    let instance = SautiHybridAiPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "status":
      result(status(language: args["language"] as? String ?? "en"))
    case "respond":
      guard let request = HybridRequest(args) else {
        result(FlutterError(code: "unknown", message: "invalid request", details: nil))
        return
      }
      Task {
        do {
          let reply = try await self.respond(request)
          DispatchQueue.main.async { result(reply) }
        } catch {
          let flutterError = HybridErrors.flutterError(for: error)
          DispatchQueue.main.async { result(flutterError) }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Status

  private func status(language: String) -> [String: Any] {
    var out: [String: Any] = [
      "onDevice": false,
      "onDeviceReason": "unsupportedOS",
      "onDeviceSupportsLanguage": false,
      "cloud": cloudAvailable(),
    ]
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
          out["onDevice"] = true
          out["onDeviceReason"] = "available"
        case .unavailable(let reason):
          out["onDeviceReason"] = String(describing: reason)
        @unknown default:
          out["onDeviceReason"] = "unknown"
        }
        out["onDeviceSupportsLanguage"] = model.supportsLocale(Locale(identifier: language))
      }
    #endif
    return out
  }

  private func cloudAvailable() -> Bool {
    #if compiler(>=6.4) && canImport(FoundationModels) && canImport(FirebaseAILogic) && canImport(GeminiLanguageModel)
      if #available(iOS 27.0, *) {
        return FirebaseApp.app() != nil
      }
    #endif
    return false
  }

  private func onDeviceReady(language: String) -> Bool {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        if case .available = model.availability {
          return model.supportsLocale(Locale(identifier: language))
        }
      }
    #endif
    return false
  }

  // MARK: - Respond

  private func respond(_ request: HybridRequest) async throws -> [String: Any] {
    #if canImport(FoundationModels)
      guard #available(iOS 26.0, *) else { throw HybridError.unavailable("iOS 26 or later is required") }

      let bridge = ToolBridge(channel: channel, requestId: request.requestId)
      let tools: [any Tool] = try request.tools.map { spec in
        BridgedTool(
          name: spec.name,
          description: spec.description,
          parameters: try ToolSchemas.schema(for: spec),
          bridge: bridge
        )
      }

      var onDeviceError: Error?
      if request.allowOnDevice && onDeviceReady(language: request.language) {
        do {
          let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            tools: tools,
            instructions: request.instructions
          )
          let response = try await session.respond(to: request.prompt)
          return ["text": response.content, "servedBy": "onDevice"]
        } catch {
          // Never repeat tool side effects (e.g. a prepared draft) on a second
          // engine: if a tool already ran, let Dart decide how to fall back.
          if bridge.callCount > 0 || !request.allowCloud { throw error }
          onDeviceError = error
        }
      }

      if request.allowCloud {
        #if compiler(>=6.4) && canImport(FirebaseAILogic) && canImport(GeminiLanguageModel)
          if #available(iOS 27.0, *), FirebaseApp.app() != nil {
            let ai = FirebaseAI.firebaseAI(backend: .googleAI(), useLimitedUseAppCheckTokens: true)
            let session = LanguageModelSession(
              model: ai.geminiLanguageModel(name: request.cloudModel),
              tools: tools,
              instructions: request.instructions
            )
            let response = try await session.respond(to: request.prompt)
            return ["text": response.content, "servedBy": "cloud"]
          }
        #endif
      }

      throw onDeviceError ?? HybridError.unavailable("no inference path available")
    #else
      throw HybridError.unavailable("Foundation Models is not available in this build")
    #endif
  }
}

// MARK: - Request

struct HybridParam {
  let name: String
  let type: String
  let description: String
  let required: Bool
  let enumValues: [String]
  let minimum: Int?
  let maximum: Int?
}

struct HybridToolSpec {
  let name: String
  let description: String
  let params: [HybridParam]
}

struct HybridRequest {
  let requestId: Int
  let instructions: String
  let prompt: String
  let tools: [HybridToolSpec]
  let language: String
  let allowOnDevice: Bool
  let allowCloud: Bool
  let cloudModel: String

  init?(_ args: [String: Any]) {
    guard let requestId = args["requestId"] as? Int,
      let instructions = args["instructions"] as? String,
      let prompt = args["prompt"] as? String,
      let cloudModel = args["cloudModel"] as? String
    else { return nil }
    self.requestId = requestId
    self.instructions = instructions
    self.prompt = prompt
    self.cloudModel = cloudModel
    language = args["language"] as? String ?? "en"
    allowOnDevice = args["allowOnDevice"] as? Bool ?? true
    allowCloud = args["allowCloud"] as? Bool ?? false
    let rawTools = args["tools"] as? [[String: Any]] ?? []
    tools = rawTools.compactMap { t in
      guard let name = t["name"] as? String, let description = t["description"] as? String else { return nil }
      let params = (t["params"] as? [[String: Any]] ?? []).compactMap { p -> HybridParam? in
        guard let pName = p["name"] as? String, let type = p["type"] as? String else { return nil }
        return HybridParam(
          name: pName,
          type: type,
          description: p["description"] as? String ?? "",
          required: p["required"] as? Bool ?? false,
          enumValues: p["enumValues"] as? [String] ?? [],
          minimum: p["minimum"] as? Int,
          maximum: p["maximum"] as? Int
        )
      }
      return HybridToolSpec(name: name, description: description, params: params)
    }
  }
}

// MARK: - Tool bridge (Swift → Dart)

/// Forwards tool calls to Dart on the main thread and counts them.
final class ToolBridge: @unchecked Sendable {
  private let channel: FlutterMethodChannel
  private let requestId: Int
  private let lock = NSLock()
  private var calls = 0

  /// Hard cap so a looping model cannot hammer the tool registry.
  static let maxCalls = 12

  init(channel: FlutterMethodChannel, requestId: Int) {
    self.channel = channel
    self.requestId = requestId
  }

  var callCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return calls
  }

  func execute(name: String, argumentsJSON: String) async throws -> String {
    lock.lock()
    calls += 1
    let count = calls
    lock.unlock()
    if count > ToolBridge.maxCalls { throw HybridError.toolLoop }

    let args: [String: Any] = ["requestId": requestId, "name": name, "arguments": argumentsJSON]
    return try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.main.async {
        self.channel.invokeMethod("executeTool", arguments: args) { reply in
          if let json = reply as? String {
            continuation.resume(returning: json)
          } else if let error = reply as? FlutterError {
            continuation.resume(throwing: HybridError.tool(error.message ?? error.code))
          } else {
            continuation.resume(throwing: HybridError.tool("no tool handler"))
          }
        }
      }
    }
  }
}

#if canImport(FoundationModels)
  /// A Foundation Models tool whose schema comes from Sauti's Dart ToolSpec and
  /// whose execution happens in Dart.
  @available(iOS 26.0, *)
  struct BridgedTool: Tool {
    typealias Arguments = GeneratedContent
    typealias Output = String

    let name: String
    let description: String
    let parameters: GenerationSchema
    let bridge: ToolBridge

    func call(arguments: GeneratedContent) async throws -> String {
      try await bridge.execute(name: name, argumentsJSON: arguments.jsonString)
    }
  }

  @available(iOS 26.0, *)
  enum ToolSchemas {
    static func schema(for spec: HybridToolSpec) throws -> GenerationSchema {
      let properties: [DynamicGenerationSchema.Property] = spec.params.map { p in
        DynamicGenerationSchema.Property(
          name: p.name,
          description: p.description,
          schema: propertySchema(tool: spec.name, param: p),
          isOptional: !p.required
        )
      }
      let root = DynamicGenerationSchema(
        name: "\(spec.name)_arguments",
        description: spec.description,
        properties: properties
      )
      return try GenerationSchema(root: root, dependencies: [])
    }

    private static func propertySchema(tool: String, param p: HybridParam) -> DynamicGenerationSchema {
      switch p.type {
      case "integer":
        var guides: [GenerationGuide<Int>] = []
        if let lo = p.minimum, let hi = p.maximum {
          guides.append(.range(lo...hi))
        } else if let lo = p.minimum {
          guides.append(.minimum(lo))
        } else if let hi = p.maximum {
          guides.append(.maximum(hi))
        }
        return DynamicGenerationSchema(type: Int.self, guides: guides)
      case "enumeration":
        return DynamicGenerationSchema(name: "\(tool)_\(p.name)", anyOf: p.enumValues)
      default:
        return DynamicGenerationSchema(type: String.self)
      }
    }
  }
#endif

// MARK: - Errors

enum HybridError: Error {
  case unavailable(String)
  case tool(String)
  case toolLoop
}

enum HybridErrors {
  static func flutterError(for error: Error) -> FlutterError {
    let (code, message) = classify(error)
    return FlutterError(code: code, message: message, details: nil)
  }

  private static func classify(_ error: Error) -> (String, String) {
    if let e = error as? HybridError {
      switch e {
      case .unavailable(let m): return ("unavailable", m)
      case .tool(let m): return ("unknown", "tool bridge: \(m)")
      case .toolLoop: return ("toolLoop", "too many tool calls")
      }
    }
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *), let e = error as? LanguageModelSession.GenerationError {
        switch e {
        case .exceededContextWindowSize: return ("contextTooLarge", String(describing: e))
        case .guardrailViolation: return ("blocked", String(describing: e))
        case .unsupportedLanguageOrLocale: return ("unsupportedLanguage", String(describing: e))
        case .assetsUnavailable: return ("unavailable", String(describing: e))
        case .rateLimited: return ("quota", String(describing: e))
        default: return ("unknown", String(describing: e))
        }
      }
    #endif
    let ns = error as NSError
    if ns.domain == NSURLErrorDomain { return ("network", ns.localizedDescription) }
    return ("unknown", String(describing: error))
  }
}
