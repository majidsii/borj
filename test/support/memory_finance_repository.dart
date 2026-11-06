import 'dart:async';

import 'package:borj/core/money/money.dart';
import 'package:borj/features/finance/domain/debt.dart';
import 'package:borj/features/finance/domain/finance_repository.dart';
import 'package:borj/features/finance/domain/finance_transaction.dart';
import 'package:borj/features/finance/domain/installment_plan.dart';

final class MemoryFinanceRepository implements FinanceRepository {
  final StreamController<List<FinanceTransaction>> _transactionsController =
      StreamController<List<FinanceTransaction>>.broadcast(sync: true);
  final StreamController<List<Debt>> _debtsController =
      StreamController<List<Debt>>.broadcast(sync: true);
  final StreamController<List<InstallmentPlan>> _installmentsController =
      StreamController<List<InstallmentPlan>>.broadcast(sync: true);

  List<FinanceTransaction> _transactions = <FinanceTransaction>[];
  List<Debt> _debts = <Debt>[];
  List<InstallmentPlan> _installments = <InstallmentPlan>[];

  List<FinanceTransaction> get transactions =>
      List<FinanceTransaction>.unmodifiable(_transactions);

  List<Debt> get debts => List<Debt>.unmodifiable(_debts);

  List<InstallmentPlan> get installments =>
      List<InstallmentPlan>.unmodifiable(_installments);

  void seed({
    List<FinanceTransaction> transactions = const <FinanceTransaction>[],
    List<Debt> debts = const <Debt>[],
    List<InstallmentPlan> installments = const <InstallmentPlan>[],
  }) {
    _transactions = List<FinanceTransaction>.from(transactions);
    _debts = List<Debt>.from(debts);
    _installments = List<InstallmentPlan>.from(installments);
  }

  void _emitTransactions() {
    _transactionsController.add(transactions);
  }

  void _emitDebts() {
    _debtsController.add(debts);
  }

  void _emitInstallments() {
    _installmentsController.add(installments);
  }

  @override
  Stream<List<FinanceTransaction>> watchTransactions() async* {
    yield transactions;
    yield* _transactionsController.stream;
  }

  @override
  Stream<List<Debt>> watchDebts() async* {
    yield debts;
    yield* _debtsController.stream;
  }

  @override
  Stream<List<InstallmentPlan>> watchInstallmentPlans() async* {
    yield installments;
    yield* _installmentsController.stream;
  }

  @override
  Future<void> addTransaction(FinanceTransaction transaction) async {
    _transactions.insert(0, transaction);
    _emitTransactions();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((transaction) => transaction.id == id);
    _emitTransactions();
  }

  @override
  Future<void> addDebt(Debt debt) async {
    _debts.insert(0, debt);
    _emitDebts();
  }

  @override
  Future<void> recordDebtPayment({
    required String debtId,
    required Money amount,
    required DateTime paidAt,
  }) async {
    final index = _debts.indexWhere((debt) => debt.id == debtId);
    if (index == -1) {
      throw StateError('Debt not found: $debtId');
    }

    final current = _debts[index];
    _debts[index] = current.copyWith(
      paid: current.paid + amount,
      updatedAtUtc: paidAt.toUtc(),
    );
    _emitDebts();
  }

  @override
  Future<void> deleteDebt(String id) async {
    _debts.removeWhere((debt) => debt.id == id);
    _emitDebts();
  }

  @override
  Future<void> addInstallmentPlan(InstallmentPlan plan) async {
    _installments.insert(0, plan);
    _emitInstallments();
  }

  @override
  Future<void> payNextInstallment({
    required String planId,
    required DateTime paidAt,
  }) async {
    final index = _installments.indexWhere((plan) => plan.id == planId);
    if (index == -1) {
      throw StateError('Installment plan not found: $planId');
    }

    final current = _installments[index];
    _installments[index] = current.copyWith(
      paidCount: current.paidCount + 1,
      updatedAtUtc: paidAt.toUtc(),
    );
    _emitInstallments();
  }

  @override
  Future<void> deleteInstallmentPlan(String id) async {
    _installments.removeWhere((plan) => plan.id == id);
    _emitInstallments();
  }

  Future<void> close() async {
    await Future.wait<void>(<Future<void>>[
      _transactionsController.close(),
      _debtsController.close(),
      _installmentsController.close(),
    ]);
  }
}
