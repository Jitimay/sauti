import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/features/banking/domain/entities/beneficiary.dart';
import 'package:sauti/features/banking/domain/services/beneficiary_resolver.dart';

const jean = Beneficiary(id: 'j', name: 'Jean Ndayishimiye', maskedAccount: '1', institution: 'x', aliases: ['Jean']);
const jeanClaude = Beneficiary(id: 'jc', name: 'Jean-Claude Bizimana', maskedAccount: '2', institution: 'x');
const mama = Beneficiary(id: 'm', name: 'Spès Niyonzima', maskedAccount: '3', institution: 'x', aliases: ['Maman']);
const eric = Beneficiary(id: 'e', name: 'Éric Hakizimana', maskedAccount: '4', institution: 'x');

void main() {
  const r = BeneficiaryResolver();

  test('resolves exact alias uniquely even when another name contains it', () {
    expect(r.resolve('Jean', [jean, jeanClaude]), const BeneficiaryResolved(jean));
  });

  test('resolves aliases and accents', () {
    expect(r.resolve('maman', [jean, mama]), const BeneficiaryResolved(mama));
    expect(r.resolve('eric', [eric]), const BeneficiaryResolved(eric));
  });

  test('ambiguous when several token matches and no exact match', () {
    const a = Beneficiary(id: 'a', name: 'Jean Ndayishimiye', maskedAccount: '1', institution: 'x');
    expect(r.resolve('jean', [a, jeanClaude]), isA<BeneficiaryAmbiguous>());
  });

  test('typo matches always require confirmation', () {
    expect(r.resolve('Erik', [eric]), isA<BeneficiaryAmbiguous>());
  });

  test('unknown names are never guessed', () {
    expect(r.resolve('Pierre', [jean, mama]), isA<BeneficiaryUnknown>());
    expect(r.resolve('', [jean]), isA<BeneficiaryUnknown>());
    expect(r.resolve('; DROP TABLE', [jean]), isA<BeneficiaryUnknown>());
  });
}
