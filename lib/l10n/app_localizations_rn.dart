// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Rundi (`rn`).
class AppLocalizationsRn extends AppLocalizations {
  AppLocalizationsRn([String locale = 'rn']) : super(locale);

  @override
  String get appName => 'Sauti';

  @override
  String get tagline => 'Ubuhinga butagira imbibe.';

  @override
  String get demoBanner => 'DEMO · banki y\'akarorero · nta mafaranga nyayo';

  @override
  String get retry => 'Subira ugerageze';

  @override
  String get cancel => 'Hagarika';

  @override
  String get continueLabel => 'Komeza';

  @override
  String get close => 'Ugara';

  @override
  String get done => 'Vyarangiye';

  @override
  String get loading => 'Birindiriwe…';

  @override
  String get offlineBanner => 'Nta interineti. Ndakwereka amakuru yabitswe.';

  @override
  String cachedAt(String time) {
    return 'Vyabitswe saa $time · si ivy\'ubu';
  }

  @override
  String get liveData => 'Ubu nyene';

  @override
  String get failureNetwork =>
      'Nta interineti. Raba interineti yawe hanyuma usubire ugerageze.';

  @override
  String get failureUnauthorized => 'Ntiwemerewe. Subira winjire.';

  @override
  String get failureInvalidCredentials =>
      'Imeyili canke ijambo kabanga si vyo.';

  @override
  String get failureEmailInUse => 'Hari konti isanzwe ikoresha iyi meyili.';

  @override
  String get failureWeakPassword =>
      'Koresha nibura inyuguti 8, harimwo indome n\'imibare.';

  @override
  String get failureUserNotFound => 'Nta konti ifise iyi meyili.';

  @override
  String get failureAuthExpired => 'Igihe co kwemeza carenze. Subira wemeze.';

  @override
  String get failureValidation => 'Raba neza ivyo wanditse.';

  @override
  String get failureInvalidAmount =>
      'Andika amafaranga abereye (make cane 500 BIF).';

  @override
  String get failureLimitExceeded => 'Ayo mafaranga arenze urugero rwawe.';

  @override
  String get failureInsufficientFunds => 'Amafaranga ufise ntashika.';

  @override
  String get failureBeneficiaryNotFound => 'Uwo muntu ntari mu bo wabitse.';

  @override
  String get failureBeneficiaryAmbiguous => 'Hari benshi bahuye. Hitamwo umwe.';

  @override
  String get failureNotFound => 'Ntibibonetse.';

  @override
  String get failureDuplicate => 'Uku kurungika kwararungitswe.';

  @override
  String get failureTransferRejected =>
      'Banki yanse. Nta mafaranga yarungitswe.';

  @override
  String get failureOfflineNotAllowed =>
      'Nta interineti. Kurungika bisaba interineti kandi ntibibikwa ngo bikorwe mu nyuma.';

  @override
  String get failureAiUnavailable => 'Umufasha ntaboneka ubu.';

  @override
  String get failureToolNotPermitted => 'Ico gikorwa nticemewe.';

  @override
  String get failureVoiceUnavailable =>
      'Kuvuga ntibikunda kuri iyi telefone. Andika icyo ushaka munsi.';

  @override
  String get failureMicrophoneCapture =>
      'Mucukumbuzi ntiyashoboye gutangura mikoro. Suzuma igikoresho co kwinjiza ijwi, wongere ugerageze canke wandike.';

  @override
  String get failureSpeechService =>
      'Serivisi yo gutahura ijwi muri mucukumbuzi ntiboneka. Gerageza iyindi mucukumbuzi canke wandike.';

  @override
  String get failureVoicePermission =>
      'Emera gukoresha mikoro mu miterere ya mucukumbuzi canke y’igikoresho, wongere ugerageze. Urashobora no kwandika.';

  @override
  String get failureVoiceLanguage =>
      'Kuvuga muri uru rurimi ntibikunda kuri iyi telefone.';

  @override
  String get failureServer => 'Hari ikibazo. Nta na kimwe cahindutse.';

  @override
  String get failureUnexpected =>
      'Hari ikitagenze neza. Nta na kimwe cahindutse.';

  @override
  String get onboardingTitle1 => 'Banki mu kuvuga';

  @override
  String get onboardingBody1 =>
      'Baza Sauti amafaranga ufise, ivyo warishe n\'ivyo wakoresheje, mu majambo yawe.';

  @override
  String get onboardingTitle2 => 'Umutekano imbere ya vyose';

  @override
  String get onboardingBody2 =>
      'Sauti ntirungika amafaranga yonyene. Wewe ubwawe wemeza kuri telefone.';

  @override
  String get onboardingTitle3 => 'Ku bantu bose';

  @override
  String get onboardingBody3 =>
      'Inyuguti nini, amabara agaragara, umusomyi w\'ikirahure n\'ijwi — canke wandike gusa.';

  @override
  String get onboardingNext => 'Ibikurikira';

  @override
  String get onboardingStart => 'Tangura';

  @override
  String get onboardingSkip => 'Simba';

  @override
  String onboardingStep(int current, int total) {
    return 'Intambwe $current kuri $total';
  }

  @override
  String get languageTitle => 'Hitamwo ururimi rwawe';

  @override
  String get languageSubtitle => 'Ushobora kuruhindura mu Ngene bigenda.';

  @override
  String get welcomeTitle => 'Banki yawe, mu ijwi ryawe';

  @override
  String get welcomeBody =>
      'Raba amafaranga ufise, tahura ivyo warishe kandi utegure kurungika mu kubaza gusa.';

  @override
  String get signIn => 'Injira';

  @override
  String get createAccount => 'Rema konti';

  @override
  String get tryDemo => 'Gerageza demo';

  @override
  String get email => 'Imeyili';

  @override
  String get password => 'Ijambo kabanga';

  @override
  String get forgotPassword => 'Wibagiye ijambo kabanga?';

  @override
  String demoCredentialsHint(String email, String password) {
    return 'Konti ya demo: $email / $password';
  }

  @override
  String get useDemoCredentials => 'Shiramwo konti ya demo';

  @override
  String get showPassword => 'Erekana ijambo kabanga';

  @override
  String get hidePassword => 'Hisha ijambo kabanga';

  @override
  String get emailInvalid => 'Andika imeyili ibereye.';

  @override
  String get passwordRequired => 'Andika ijambo kabanga.';

  @override
  String get fullName => 'Izina ryose';

  @override
  String get nameInvalid => 'Andika izina ryawe.';

  @override
  String get passwordRules => 'Nibura inyuguti 8, harimwo indome n\'imibare.';

  @override
  String get registerTitle => 'Rema konti yawe';

  @override
  String get registerDemoNote =>
      'Demo: konti ushaka kuremana zibikwa kuri ubu bushabire kandi zikoresha amakuru y\'akarorero. Nta banki nyayo irimo.';

  @override
  String get resetTitle => 'Subiza ijambo kabanga';

  @override
  String get resetBody =>
      'Andika imeyili yawe tukurungikire umurongo wo guhindura.';

  @override
  String get sendResetLink => 'Rungika umurongo';

  @override
  String get resetSent =>
      'Nimba hari konti ifise iyi meyili, umurongo warungitswe.';

  @override
  String get resetDemoNote => 'Demo: nta meyili irungikwa.';

  @override
  String greetingName(String name) {
    return 'Amahoro, $name';
  }

  @override
  String get availableBalance => 'Amafaranga ufise';

  @override
  String get showBalance => 'Erekana amafaranga asigaye';

  @override
  String get hideBalance => 'Hisha amafaranga asigaye';

  @override
  String get recentActivity => 'Ivyakozwe vya vuba';

  @override
  String get seeAll => 'Raba vyose';

  @override
  String get quickActions => 'Ivyo gukora vuba';

  @override
  String get actionSend => 'Rungika';

  @override
  String get actionHistory => 'Ivyakozwe';

  @override
  String get actionInsights => 'Isesengura';

  @override
  String get actionAccounts => 'Konti';

  @override
  String get talkToSauti => 'Vugana na Sauti';

  @override
  String get talkToSautiHint => 'Ugurura umufasha w\'ijwi';

  @override
  String get notificationsTooltip => 'Ubutumwa';

  @override
  String unreadNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ubutumwa bushasha $count',
      one: 'Ubutumwa bushasha 1',
      zero: 'Nta butumwa bushasha',
    );
    return '$_temp0';
  }

  @override
  String get noTransactionsYet => 'Nta vyakozwe biraba.';

  @override
  String get transactionsTitle => 'Ivyakozwe';

  @override
  String get filterAll => 'Vyose';

  @override
  String get filterIncoming => 'Ayinjiye';

  @override
  String get filterOutgoing => 'Ayasohotse';

  @override
  String get searchTransactions => 'Rondera ukoresheje izina';

  @override
  String get received => 'Vyakiriwe';

  @override
  String get paid => 'Vyarishwe';

  @override
  String txSemanticIn(String amount, String name, String date) {
    return 'Wakiriye $amount biva kwa $name, $date';
  }

  @override
  String txSemanticOut(String amount, String name, String date) {
    return 'Warishe $amount kuri $name, $date';
  }

  @override
  String get transactionDetailsTitle => 'Ibiranga igikorwa';

  @override
  String get detailAmount => 'Amafaranga';

  @override
  String get detailDate => 'Itariki';

  @override
  String get detailCategory => 'Umurwi';

  @override
  String get detailCounterparty => 'Na';

  @override
  String get detailReference => 'Inomero';

  @override
  String get detailFee => 'Amafaranga y\'igikorwa';

  @override
  String get detailStatus => 'Uko bimeze';

  @override
  String get recurringPayment => 'Uriha ibi buri kwezi.';

  @override
  String shareOfCategory(int percent, String category) {
    return '$percent% vy\'ivyo wakoresheje mu $category uku kwezi.';
  }

  @override
  String get askSautiExplain => 'Saba Sauti gusobanura';

  @override
  String get categoryIncome => 'Ayinjiye';

  @override
  String get categoryTransfer => 'Ayarungitswe';

  @override
  String get categoryTransport => 'Ingendo';

  @override
  String get categoryGroceries => 'Ivyokurya';

  @override
  String get categoryUtilities => 'Amazi n\'umuyagankuba';

  @override
  String get categoryAirtime => 'Ama unite';

  @override
  String get categoryHealth => 'Amagara';

  @override
  String get categoryEducation => 'Amashure';

  @override
  String get categoryFees => 'Amafaranga ya banki';

  @override
  String get categoryOther => 'Ibindi';

  @override
  String get statusCompleted => 'Vyarangiye';

  @override
  String get statusPending => 'Birindiriwe';

  @override
  String get statusFailed => 'Vyanse';

  @override
  String get accountsTitle => 'Konti';

  @override
  String get accountTypeCurrent => 'Konti y\'ivy\'umunsi';

  @override
  String get accountTypeSavings => 'Kuzigama';

  @override
  String get accountTypeWallet => 'Ikofi ya telefone';

  @override
  String accountNumber(String number) {
    return 'Konti $number';
  }

  @override
  String get balanceLabel => 'Amafaranga ari kuri konti';

  @override
  String get transferTitle => 'Rungika amafaranga';

  @override
  String get chooseRecipient => 'Hitamwo uwo urungikira';

  @override
  String get amountLabel => 'Amafaranga (BIF)';

  @override
  String get noteLabel => 'Icitonderwa (si ngombwa)';

  @override
  String get reviewTransfer => 'Raba neza ivyo urungika';

  @override
  String get savedRecipientsOnly =>
      'Kubw\'umutekano wawe, urungikira gusa abo wabitse.';

  @override
  String get confirmTitle => 'Emeza kurungika';

  @override
  String get confirmTo => 'Kuri';

  @override
  String get confirmFrom => 'Bivuye kuri';

  @override
  String get confirmFee => 'Amafaranga y\'igikorwa';

  @override
  String get confirmTotal => 'Vyose hamwe';

  @override
  String get confirmBalanceAfter => 'Uzosigarana';

  @override
  String get notSentYet => 'Nta na kimwe kirarungikwa.';

  @override
  String get stepVerify => 'Intambwe 1 · Emeza ko ari wewe';

  @override
  String get stepConfirm => 'Intambwe 2 · Emeza hanyuma urungike';

  @override
  String get authenticateButton => 'Emeza ko ari jewe';

  @override
  String authReason(String amount, String name) {
    return 'Emeza ko ari wewe kugira urungikire $name $amount';
  }

  @override
  String get usePassword => 'Koresha ijambo kabanga';

  @override
  String get passwordFallbackHint =>
      'Andika ijambo kabanga rya Sauti. Rirasuzumwa rimwe ntiribikwa. Ntuzorivuge n\'ijwi.';

  @override
  String get verifyPassword => 'Suzuma ijambo kabanga';

  @override
  String get verified => 'Vyemejwe ko ari wewe';

  @override
  String get authExpiresHint =>
      'Kubw\'umutekano, kwemeza kurangira inyuma y\'iminota 2.';

  @override
  String sendNow(String amount) {
    return 'Rungika $amount ubu';
  }

  @override
  String get cancelTransfer => 'Hagarika kurungika';

  @override
  String get transferCancelled =>
      'Kurungika kwahagaritswe. Nta mafaranga yarungitswe.';

  @override
  String get sending => 'Birarungikwa… ntugare porogarama.';

  @override
  String get deviceAuthUnavailable =>
      'Kwemeza ukoresheje telefone ntibikunda. Koresha ijambo kabanga.';

  @override
  String get receiptTitle => 'Kurungika vyarangiye';

  @override
  String get receiptVerified => 'Vyemejwe na banki';

  @override
  String get receiptReference => 'Inomero';

  @override
  String get receiptDate => 'Itariki';

  @override
  String get receiptNewBalance => 'Amafaranga usigaranye';

  @override
  String receiptAmountTo(String amount, String name) {
    return '$amount yarungikiwe $name';
  }

  @override
  String receiptSpoken(String amount, String name, String reference) {
    return 'Kurungikira $name $amount vyemejwe na banki. Inomero $reference.';
  }

  @override
  String get transferFailedTitle => 'Kurungika ntivyakunze';

  @override
  String get transferUnknownBody =>
      'Ntitwashoboye kwemeza. Raba ivyakozwe imbere yo gusubira — gusubira ntibirungika kabiri.';

  @override
  String get insightsTitle => 'Isesengura ry\'ivyo wakoresheje';

  @override
  String get thisMonth => 'Uku kwezi';

  @override
  String get lastMonth => 'Ukwezi guheze';

  @override
  String get totalSpent => 'Ivyakoreshejwe';

  @override
  String get totalReceived => 'Ivyakiriwe';

  @override
  String spentMoreThanLast(int percent) {
    return '$percent% kurusha ukwezi guheze';
  }

  @override
  String spentLessThanLast(int percent) {
    return '$percent% munsi y\'ukwezi guheze';
  }

  @override
  String get byCategory => 'Ukurikije umurwi';

  @override
  String get noSpending => 'Nta vyakoreshejwe muri iki gihe.';

  @override
  String categoryShareSemantic(String category, String amount, int percent) {
    return '$category: $amount, $percent% vy\'ivyakoreshejwe';
  }

  @override
  String get notificationsTitle => 'Ubutumwa';

  @override
  String get noNotifications => 'Nta butumwa ufise.';

  @override
  String get markAsRead => 'Shira ko wasomye';

  @override
  String get unread => 'Butarasomwa';

  @override
  String notifPaymentReceived(String amount, String name) {
    return 'Wakiriye $amount biva kwa $name.';
  }

  @override
  String notifTransferSent(String amount, String name) {
    return 'Warungitse $amount kuri $name.';
  }

  @override
  String get notifSecurityNewDevice =>
      'Umutekano: hari uwinjiye akoresheje telefone nshasha.';

  @override
  String get notifSecurityGeneric =>
      'Hari ikibazo c\'umutekano kuri konti yawe.';

  @override
  String get notifReminderBill =>
      'Wibuke: igihe co kuriha amazi n\'umuyagankuba kiregereje.';

  @override
  String get notifReminderGeneric => 'Ufise ubutumwa bwo kukwibutsa.';

  @override
  String get readAloud => 'Soma n\'ijwi';

  @override
  String get assistantTitle => 'Umufasha Sauti';

  @override
  String get typeMessage => 'Andika ico usaba';

  @override
  String get send => 'Rungika';

  @override
  String get startListening => 'Tangura kuvuga';

  @override
  String get stopListening => 'Hagarika kwumviriza';

  @override
  String get stateIdle => 'Kora kuri mikoro uvuge, canke wandike hepfo.';

  @override
  String get stateMicrophoneAccess => 'Turindiriye uruhusha rwa mikoro…';

  @override
  String get stateListening => 'Ndakwumviriza…';

  @override
  String get stateProcessing => 'Ndiko ndatekereza…';

  @override
  String get stateResponding => 'Ndiko ndavuga…';

  @override
  String get stateAwaitingConfirmation => 'Ndindiriye ko wemeza';

  @override
  String get stateError => 'Hari ikitagenze. Subira canke wandike.';

  @override
  String toolRunning(String what) {
    return 'Ndiko ndaraba $what…';
  }

  @override
  String get toolWhatBalance => 'amafaranga ufise';

  @override
  String get toolWhatTransactions => 'ivyakozwe';

  @override
  String get toolWhatSpending => 'ivyo wakoresheje';

  @override
  String get toolWhatBeneficiaries => 'abo urungikira';

  @override
  String get toolWhatTransfer => 'ibiranga kurungika';

  @override
  String get toolWhatNotifications => 'ubutumwa bwawe';

  @override
  String get repeat => 'Subiramwo';

  @override
  String get muteVoice => 'Zimya ijwi';

  @override
  String get unmuteVoice => 'Subiza ijwi';

  @override
  String get stopSpeaking => 'Hagarika kuvuga';

  @override
  String get clearConversation => 'Futa ikiyago';

  @override
  String get historyTitle => 'Ivyavuzwe kera';

  @override
  String get historyEmpty => 'Nta kiyago kiraba.';

  @override
  String get historyPrivacyNote =>
      'Bibitswe kuri iyi telefone gusa, mu buryo bukingiwe.';

  @override
  String get providerCloud => 'AI yo kuri interineti';

  @override
  String get providerLocal => 'Uburyo bworoshe';

  @override
  String get providerOnDeviceAi => 'AI yo kuri telefone · ibanga';

  @override
  String get fallbackNotice => 'AI nyamukuru ntiboneka — vyishuwe n\'iyindi';

  @override
  String get tryAsking => 'Gerageza kubaza';

  @override
  String get suggestionBalance => 'Amafaranga mfise ni angahe?';

  @override
  String get suggestionExplain => 'Sobanura ivyakozwe vya nyuma';

  @override
  String get suggestionSend => 'Rungikira Jean 20 000 BIF';

  @override
  String get suggestionSpending => 'Nakoresheje angahe uku kwezi?';

  @override
  String get suggestionNotifications => 'Soma ubutumwa bwanje';

  @override
  String get reviewAndConfirm => 'Raba hanyuma wemeze';

  @override
  String get draftCardTitle => 'Kurungika vyateguwe — ntibirarungikwa';

  @override
  String get chooseRecipientCard => 'Ni nde ushaka?';

  @override
  String sendToThisPerson(String amount, String name) {
    return 'Rungikira $name $amount';
  }

  @override
  String voiceLanguageUnsupported(String language) {
    return 'Kuvuga mu $language ntibikunda kuri iyi telefone. Urashobora kwandika ico usaba.';
  }

  @override
  String get useFrenchVoice => 'Koresha ijwi ry\'igifaransa';

  @override
  String get noSpeechHeard => 'Nta co numvise. Kora kuri mikoro usubire.';

  @override
  String ttsUnavailable(String language) {
    return 'Gusoma mu $language ntibishoboka ubu. Urashobora gusoma inyishu ku rubuga.';
  }

  @override
  String get you => 'Wewe';

  @override
  String get settingsTitle => 'Ingene bigenda';

  @override
  String get profileSection => 'Umwirondoro';

  @override
  String get languageSetting => 'Ururimi';

  @override
  String get accessibilitySetting => 'Uburyo bworoshe';

  @override
  String get cloudAiSetting => 'Koresha AI yo kuri interineti (Gemini)';

  @override
  String get cloudAiDescription =>
      'Yemerera Google Gemini gukoresha ivyo usavye, ikiganiro giheruka n’amakuru amwe ya banki. Uyizimije, inyishu za AI ziguma kuri iki gikoresho.';

  @override
  String get naturalVoiceSetting => 'Ijwi risa n\'iry\'umuntu (Gemini)';

  @override
  String get naturalVoiceDescription =>
      'Inyishu zo kuri interineti zirashobora kurungikwa kuri Gemini biciye kuri Firebase kugira zisomwe neza. Inyishu z’ibanga zisomwa n’ijwi ry’igikoresho.';

  @override
  String get cloudAiNotConfigured =>
      'AI yo kuri interineti ntiyashizweho. Sauti ikoresha umufasha wo kuri telefone.';

  @override
  String get demoControls => 'Ivyo kugenzura demo';

  @override
  String get simulateOffline => 'Igereranya nta interineti';

  @override
  String get simulateOfflineDescription =>
      'Yerekana ingene Sauti ikora nta interineti.';

  @override
  String get signOut => 'Sohoka';

  @override
  String get aboutSection => 'Ivyerekeye';

  @override
  String get environmentDemo => 'Aho bikorera: DEMO (banki y\'akarorero)';

  @override
  String get environmentLive => 'Aho bikorera: Firebase';

  @override
  String get accessibilityTitle => 'Uburyo bworoshe';

  @override
  String get textSize => 'Ingene inyuguti zingana';

  @override
  String textSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get highContrast => 'Amabara agaragara cane';

  @override
  String get highContrastDescription =>
      'Amabara n\'imbibe bikomeye ku batabona neza.';

  @override
  String get voiceConsentTitle => 'Usome inyishu n’ijwi?';

  @override
  String get voiceConsentBody =>
      'Sauti irashobora gusoma inyishu zawe. Abantu bari hafi barashobora kwumva amakuru yawe ya banki. Urashobora guhindura iri hitamwo mu miterere y’ukworohereza gukoresha.';

  @override
  String get voiceConsentDecline => 'Gumiza inyishu mu gacerere';

  @override
  String get voiceConsentAllow => 'Emera inyishu z’ijwi';

  @override
  String get voiceFeedback => 'Soma inyishu n\'ijwi';

  @override
  String get speechSpeed => 'Umuvuduko w\'ijwi';

  @override
  String get speechSlow => 'Buhoro';

  @override
  String get speechNormal => 'Bisanzwe';

  @override
  String get speechFast => 'Vuba';

  @override
  String get simplifiedMode => 'Uburyo bworoshe cane';

  @override
  String get simplifiedModeDescription =>
      'Ibintu bike ku kirahure n\'utubuto tunini.';

  @override
  String get reduceMotion => 'Gabanya ibinyiganyiga';

  @override
  String get previewText => 'Akarorero: ufise 250 000 BIF.';

  @override
  String get navHome => 'Intango';

  @override
  String get navAssistant => 'Umufasha';

  @override
  String get navActivity => 'Ivyakozwe';

  @override
  String get navInsights => 'Ivyegeranyo';

  @override
  String get navSettings => 'Ingene bigenda';

  @override
  String get kirundiDraftNote =>
      'Ubusobanuro mu Kirundi ni ubwa mbere, buriko burasuzumwa.';

  @override
  String get onDeviceAiSetting => 'AI yihishije kuri telefone (Gemini Nano)';

  @override
  String get onDeviceAiReady =>
      'Iriteguye. Ivyo usaba vyumvikanira kuri iyi telefone, kandi bikora ata interineti.';

  @override
  String get onDeviceAiDownloadable =>
      'Irashobora gukora kuri iyi telefone. Yimanure rimwe (biruta kuri Wi-Fi) kugira ngo ivyo usaba bigume kuri telefone.';

  @override
  String get onDeviceAiDownloading => 'Turiko turimanura AI ya telefone…';

  @override
  String get onDeviceAiUnavailable =>
      'Ntikora kuri iyi telefone. Sauti ikoresha AI yo kuri interineti canke uburyo bworoshe.';

  @override
  String get onDeviceAiDownload => 'Kumanura';
}
