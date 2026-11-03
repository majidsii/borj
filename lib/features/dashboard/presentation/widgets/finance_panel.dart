import 'dart:async';

import 'package:dashboard_shakhsi/app/theme/original_design_tokens.dart';
import 'package:dashboard_shakhsi/app/widgets/original_controls.dart';
import 'package:dashboard_shakhsi/app/widgets/original_glass.dart';
import 'package:dashboard_shakhsi/core/date_time/persian_date_label.dart';
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/ids/id_generator.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/core/money/money_input_formatter.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/widgets/finance_charts.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/widgets/finance_preview_models.dart'
    show FinanceEntryType, FinancePreviewMath;
import 'package:dashboard_shakhsi/features/finance/application/finance_summary.dart';
import 'package:dashboard_shakhsi/features/finance/domain/debt.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:dashboard_shakhsi/features/finance/domain/installment_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class FinancePanel extends ConsumerStatefulWidget {
  const FinancePanel({super.key});

  @override
  ConsumerState<FinancePanel> createState() => _FinancePanelState();
}

final class _FinancePanelState extends ConsumerState<FinancePanel> {
  static const IdGenerator _idGenerator = UuidV7IdGenerator();
  static const List<String> _expenseCategories = <String>[
    'خوراک',
    'حمل‌ونقل',
    'خرید',
    'مسکن',
    'قبوض',
    'سلامت',
    'تفریح',
    'سایر',
  ];
  static const List<String> _incomeCategories = <String>[
    'حقوق',
    'فریلنس',
    'فروش',
    'هدیه',
    'سایر',
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _debtPaidController = TextEditingController();
  final TextEditingController _installmentCountController =
      TextEditingController();
  final TextEditingController _installmentPaidController =
      TextEditingController();
  final TextEditingController _paymentController = TextEditingController();

  FinanceEntryType _entryType = FinanceEntryType.expense;
  int _expenseCategoryIndex = 0;
  int _incomeCategoryIndex = 0;
  int _donutScope = 0;
  int _transactionFilter = 0;
  String? _openDebtId;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _debtPaidController.dispose();
    _installmentCountController.dispose();
    _installmentPaidController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final transactions =
        ref.watch(financeTransactionsProvider).asData?.value ??
        const <FinanceTransaction>[];
    final debts = ref.watch(debtsProvider).asData?.value ?? const <Debt>[];
    final installments =
        ref.watch(installmentPlansProvider).asData?.value ??
        const <InstallmentPlan>[];
    final reports = ref.watch(financeReportServiceProvider);
    final FinanceSummary totals;
    final List<FinanceMonthPoint> trend;
    final List<FinanceCategoryPoint> categories;
    final List<FinanceDayPoint> week;
    try {
      totals = reports.summary(
        transactions: transactions,
        debts: debts,
        installments: installments,
      );
      trend = reports.trend(transactions: transactions);
      categories = reports.categories(
        transactions: transactions,
        currentMonthOnly: _donutScope == 0,
      );
      week = reports.week(transactions: transactions);
    } on MoneyOverflowFailure {
      return const _OutOfRangeNotice();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 16,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'مالی من',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 30,
                      height: 1.25,
                      letterSpacing: -.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    PersianDateLabel.full(DateTime.now()),
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _statusText(
                      totals,
                      transactions: transactions,
                      debts: debts,
                      installments: installments,
                    ),
                    style: TextStyle(
                      color: totals.monthExpense > totals.monthIncome
                          ? palette.expense
                          : palette.accent,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              OriginalGhostButton(
                label: 'گزارش و خروجی',
                icon: Icons.file_download_outlined,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SummaryGrid(totals: totals),
        const SizedBox(height: 14),
        _FinanceCard(
          title: 'ثبت جدید',
          icon: Icons.add_rounded,
          child: Column(
            children: <Widget>[
              _FinanceSegmentedControl(
                selected: _entryType.index,
                onSelected: (value) {
                  setState(() => _entryType = FinanceEntryType.values[value]);
                },
              ),
              const SizedBox(height: 12),
              _EntryForm(
                type: _entryType,
                titleController: _titleController,
                amountController: _amountController,
                debtPaidController: _debtPaidController,
                installmentCountController: _installmentCountController,
                installmentPaidController: _installmentPaidController,
                category: _currentCategory,
                onCategoryPressed: _cycleCategory,
                onSubmit: () => unawaited(_submitEntry()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _FinanceCard(
          title: 'روند ۶ ماه اخیر',
          icon: Icons.show_chart_rounded,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _LegendDot(color: palette.income, label: 'درآمد'),
              const SizedBox(width: 16),
              _LegendDot(color: palette.expense, label: 'هزینه'),
            ],
          ),
          child: FinanceTrendChart(points: trend),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 640;
            final cardWidth = stacked
                ? constraints.maxWidth
                : (constraints.maxWidth - 14) / 2;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: <Widget>[
                SizedBox(
                  width: cardWidth,
                  child: _FinanceCard(
                    title: 'هزینه‌ها بر اساس دسته',
                    icon: Icons.donut_small_rounded,
                    trailing: OriginalPills(
                      compact: true,
                      items: const <String>['این ماه', 'همه'],
                      selected: _donutScope,
                      onSelected: (value) {
                        setState(() => _donutScope = value);
                      },
                    ),
                    child: FinanceDonutChart(
                      points: categories,
                      currentMonthOnly: _donutScope == 0,
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _FinanceCard(
                    title: 'هزینه ۷ روز اخیر',
                    icon: Icons.bar_chart_rounded,
                    child: FinanceWeekChart(points: week),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _FinanceCard(
          title: 'بدهی‌ها و اقساط',
          icon: Icons.credit_card_rounded,
          child: _buildObjects(debts, installments),
        ),
        const SizedBox(height: 14),
        _FinanceCard(
          title: 'تراکنش‌های اخیر',
          icon: Icons.format_list_bulleted_rounded,
          trailing: OriginalPills(
            compact: true,
            items: const <String>['همه', 'درآمد', 'هزینه'],
            selected: _transactionFilter,
            onSelected: (value) {
              setState(() => _transactionFilter = value);
            },
          ),
          child: _buildTransactions(transactions),
        ),
      ],
    );
  }

  String get _currentCategory {
    if (_entryType == FinanceEntryType.income) {
      return _incomeCategories[_incomeCategoryIndex];
    }
    return _expenseCategories[_expenseCategoryIndex];
  }

  String _statusText(
    FinanceSummary totals, {
    required List<FinanceTransaction> transactions,
    required List<Debt> debts,
    required List<InstallmentPlan> installments,
  }) {
    if (transactions.isEmpty && debts.isEmpty && installments.isEmpty) {
      return 'اولین تراکنش خود را ثبت کنید';
    }
    if (totals.monthExpense > totals.monthIncome) {
      return '⚠️ هزینه‌های این ماه از درآمد بیشتر است';
    }
    if (totals.monthIncome.isPositive) {
      return 'پس‌انداز این ماه: '
          '${FinancePreviewMath.money(totals.monthIncome - totals.monthExpense)} تومان';
    }
    return 'هزینه این ماه: '
        '${FinancePreviewMath.money(totals.monthExpense)} تومان';
  }

  void _cycleCategory() {
    setState(() {
      if (_entryType == FinanceEntryType.income) {
        _incomeCategoryIndex =
            (_incomeCategoryIndex + 1) % _incomeCategories.length;
      } else {
        _expenseCategoryIndex =
            (_expenseCategoryIndex + 1) % _expenseCategories.length;
      }
    });
  }

  Future<void> _submitEntry() async {
    final amount = FinancePreviewMath.parseAmount(_amountController.text);
    if (!amount.isPositive) return;
    final title = _titleController.text.trim().isEmpty
        ? 'بدون عنوان'
        : _titleController.text.trim();
    final now = DateTime.now().toUtc();
    final repository = ref.read(financeRepositoryProvider);

    switch (_entryType) {
      case FinanceEntryType.expense:
      case FinanceEntryType.income:
        await repository.addTransaction(
          FinanceTransaction.create(
            id: _idGenerator.next(),
            type: _entryType == FinanceEntryType.income
                ? FinanceTransactionType.income
                : FinanceTransactionType.expense,
            title: title,
            category: _currentCategory,
            amount: amount,
            occurredAtUtc: now,
            createdAtUtc: now,
          ),
        );
        break;
      case FinanceEntryType.debt:
        final paid = FinancePreviewMath.parseAmount(
          _debtPaidController.text,
        ).clamp(Money.zeroIRT, amount);
        await repository.addDebt(
          Debt(
            id: _idGenerator.next(),
            title: title,
            total: amount,
            paid: paid,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        _debtPaidController.clear();
        break;
      case FinanceEntryType.installment:
        final count = FinancePreviewMath.parseCount(
          _installmentCountController.text,
        );
        if (count < 1) return;
        final paidCount = FinancePreviewMath.parseCount(
          _installmentPaidController.text,
        ).clamp(0, count).toInt();
        await repository.addInstallmentPlan(
          InstallmentPlan(
            id: _idGenerator.next(),
            title: title,
            perInstallment: amount,
            installmentCount: count,
            paidCount: paidCount,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        _installmentCountController.clear();
        _installmentPaidController.clear();
        break;
    }

    if (!mounted) return;
    _titleController.clear();
    _amountController.clear();
  }

  Future<void> _applyDebtPayment(Debt debt) async {
    final payment = FinancePreviewMath.parseAmount(
      _paymentController.text,
    ).clamp(Money.zeroIRT, debt.remaining);
    if (!payment.isPositive) return;

    await ref
        .read(financeRepositoryProvider)
        .recordDebtPayment(
          debtId: debt.id,
          amount: payment,
          paidAt: DateTime.now().toUtc(),
        );

    if (!mounted) return;
    setState(() {
      _openDebtId = null;
      _paymentController.clear();
    });
  }

  Widget _buildObjects(List<Debt> debts, List<InstallmentPlan> installments) {
    if (debts.isEmpty && installments.isEmpty) {
      return const _EmptySection(
        title: 'بدهی یا قسطی ثبت نشده',
        subtitle: 'از فرم بالا با انتخاب «بدهی» یا «قسط» اضافه کنید.',
      );
    }

    return Column(
      children: <Widget>[
        ...debts.map(
          (debt) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DebtRow(
              debt: debt,
              paymentController: _paymentController,
              paymentOpen: _openDebtId == debt.id,
              onTogglePayment: () {
                setState(() {
                  _openDebtId = _openDebtId == debt.id ? null : debt.id;
                  _paymentController.clear();
                });
              },
              onApplyPayment: () => unawaited(_applyDebtPayment(debt)),
              onDelete: () => unawaited(
                ref.read(financeRepositoryProvider).deleteDebt(debt.id),
              ),
            ),
          ),
        ),
        ...installments.map(
          (installment) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InstallmentRow(
              installment: installment,
              onPay: installment.settled
                  ? null
                  : () => unawaited(
                      ref
                          .read(financeRepositoryProvider)
                          .payNextInstallment(
                            planId: installment.id,
                            paidAt: DateTime.now().toUtc(),
                          ),
                    ),
              onDelete: () => unawaited(
                ref
                    .read(financeRepositoryProvider)
                    .deleteInstallmentPlan(installment.id),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactions(List<FinanceTransaction> transactions) {
    final visible = transactions
        .where((transaction) {
          if (_transactionFilter == 1) return transaction.isIncome;
          if (_transactionFilter == 2) return transaction.isExpense;
          return true;
        })
        .take(40)
        .toList(growable: false);

    if (visible.isEmpty) {
      return const _EmptySection(
        title: 'تراکنشی نیست',
        subtitle: 'درآمد و هزینه‌ها اینجا فهرست می‌شوند.',
      );
    }

    return Column(
      children: visible.indexed
          .map((entry) {
            return _TransactionRow(
              transaction: entry.$2,
              showDivider: entry.$1 < visible.length - 1,
              onDelete: () => unawaited(
                ref
                    .read(financeRepositoryProvider)
                    .deleteTransaction(entry.$2.id),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

final class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.totals});

  final FinanceSummary totals;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700
            ? 4
            : constraints.maxWidth >= 360
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _SummaryCard(
              key: const ValueKey<String>('finance-summary-balance'),
              width: width,
              icon: Icons.account_balance_wallet_outlined,
              iconColor: palette.accent,
              iconBackground: palette.accentSoft,
              label: 'موجودی خالص',
              value: totals.balance,
              negative: totals.balance.isNegative,
            ),
            _SummaryCard(
              key: const ValueKey<String>('finance-summary-income'),
              width: width,
              icon: Icons.trending_up_rounded,
              iconColor: palette.income,
              iconBackground: palette.incomeSoft,
              label: 'درآمد این ماه',
              value: totals.monthIncome,
            ),
            _SummaryCard(
              key: const ValueKey<String>('finance-summary-expense'),
              width: width,
              icon: Icons.trending_down_rounded,
              iconColor: palette.expense,
              iconBackground: palette.expenseSoft,
              label: 'هزینه این ماه',
              value: totals.monthExpense,
            ),
            _SummaryCard(
              key: const ValueKey<String>('finance-summary-debt'),
              width: width,
              icon: Icons.payments_outlined,
              iconColor: palette.amber,
              iconBackground: palette.amberSoft,
              label: 'بدهی باقی‌مانده',
              value: totals.debtRemaining,
            ),
          ],
        );
      },
    );
  }
}

final class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    this.negative = false,
    super.key,
  });

  final double width;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final Money value;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return SizedBox(
      width: width,
      child: OriginalGlass(
        radius: OriginalDesignTokens.summaryRadius,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Flexible(
                  child: Text(
                    FinancePreviewMath.money(value),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: negative ? palette.expense : palette.ink,
                      fontSize: 19,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'تومان',
                    style: TextStyle(
                      color: palette.faint,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _FinanceCard extends StatelessWidget {
  const _FinanceCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return OriginalGlass(
      radius: OriginalDesignTokens.cardRadius,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, color: palette.accent, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

final class _FinanceSegmentedControl extends StatelessWidget {
  const _FinanceSegmentedControl({
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final colors = <Color>[
      palette.expense,
      palette.income,
      palette.amber,
      palette.violet,
    ];
    const labels = <String>['هزینه', 'درآمد', 'بدهی', 'قسط'];
    const keys = <String>[
      'finance-type-expense',
      'finance-type-income',
      'finance-type-debt',
      'finance-type-installment',
    ];

    return OriginalFieldSurface(
      radius: OriginalDesignTokens.pillRadius,
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        height: 34,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / labels.length;
            return Stack(
              children: <Widget>[
                AnimatedPositionedDirectional(
                  duration: const Duration(milliseconds: 350),
                  curve: const Cubic(.32, 1.35, .4, 1),
                  start: segmentWidth * selected,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.thumb,
                      borderRadius: BorderRadius.circular(
                        OriginalDesignTokens.pillRadius,
                      ),
                      border: Border.all(color: palette.hair),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: palette.shadowSecondary,
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: palette.hairTop,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List<Widget>.generate(labels.length, (index) {
                    final active = selected == index;
                    return Expanded(
                      child: OriginalPressable(
                        key: ValueKey<String>(keys[index]),
                        onPressed: () => onSelected(index),
                        pressedScale: .97,
                        semanticLabel: labels[index],
                        borderRadius: BorderRadius.circular(
                          OriginalDesignTokens.pillRadius,
                        ),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              color: active ? colors[index] : palette.muted,
                              fontFamily: 'Vazirmatn',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                            child: Text(labels[index]),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _EntryForm extends StatelessWidget {
  const _EntryForm({
    required this.type,
    required this.titleController,
    required this.amountController,
    required this.debtPaidController,
    required this.installmentCountController,
    required this.installmentPaidController,
    required this.category,
    required this.onCategoryPressed,
    required this.onSubmit,
  });

  final FinanceEntryType type;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController debtPaidController;
  final TextEditingController installmentCountController;
  final TextEditingController installmentPaidController;
  final String category;
  final VoidCallback onCategoryPressed;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final titleHint = switch (type) {
      FinanceEntryType.expense => 'مثلاً: خرید هفتگی',
      FinanceEntryType.income => 'مثلاً: حقوق این ماه',
      FinanceEntryType.debt => 'مثلاً: قرض از علی',
      FinanceEntryType.installment => 'مثلاً: قسط خودرو',
    };
    final amountLabel = switch (type) {
      FinanceEntryType.debt => 'مبلغ کل بدهی',
      FinanceEntryType.installment => 'مبلغ هر قسط',
      _ => 'مبلغ',
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final singleColumn = constraints.maxWidth < 480;
        final fieldWidth = singleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            SizedBox(
              width: constraints.maxWidth,
              child: _LabeledField(
                fieldKey: 'finance-title-field',
                controller: titleController,
                label: 'عنوان',
                hint: titleHint,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _LabeledField(
                fieldKey: 'finance-amount-field',
                controller: amountController,
                label: amountLabel,
                hint: '۰',
                unit: 'تومان',
                numeric: true,
                money: true,
              ),
            ),
            if (type == FinanceEntryType.expense ||
                type == FinanceEntryType.income)
              SizedBox(
                width: fieldWidth,
                child: _LabeledSelect(
                  label: 'دسته',
                  value: category,
                  onPressed: onCategoryPressed,
                ),
              ),
            if (type == FinanceEntryType.debt)
              SizedBox(
                width: fieldWidth,
                child: _LabeledField(
                  fieldKey: 'finance-debt-paid-field',
                  controller: debtPaidController,
                  label: 'پرداخت‌شده تاکنون (اختیاری)',
                  hint: '۰',
                  unit: 'تومان',
                  numeric: true,
                  money: true,
                ),
              ),
            if (type == FinanceEntryType.installment) ...<Widget>[
              SizedBox(
                width: fieldWidth,
                child: _LabeledField(
                  fieldKey: 'finance-installment-count-field',
                  controller: installmentCountController,
                  label: 'تعداد کل اقساط',
                  hint: 'مثلاً ۱۲',
                  numeric: true,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _LabeledField(
                  fieldKey: 'finance-installment-paid-field',
                  controller: installmentPaidController,
                  label: 'پرداخت‌شده تاکنون (تعداد)',
                  hint: '۰',
                  numeric: true,
                ),
              ),
            ],
            SizedBox(
              width: constraints.maxWidth,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OriginalPrimaryButton(
                  key: const ValueKey<String>('finance-submit'),
                  icon: Icons.check_rounded,
                  label: 'ثبت',
                  onPressed: onSubmit,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.hint,
    this.unit,
    this.numeric = false,
    this.money = false,
  });

  final String fieldKey;
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? unit;
  final bool numeric;
  final bool money;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Column(
      key: ValueKey<String>(fieldKey),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 5),
        OriginalTextField(
          controller: controller,
          hintText: hint,
          keyboardType: money
              ? const TextInputType.numberWithOptions(decimal: true)
              : numeric
              ? TextInputType.number
              : TextInputType.text,
          textDirection: numeric ? TextDirection.ltr : TextDirection.rtl,
          textAlign: numeric ? TextAlign.left : TextAlign.start,
          inputFormatters: money
              ? const <TextInputFormatter>[MoneyInputFormatter()]
              : numeric
              ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
              : null,
          suffix: unit == null
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(end: 15),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      unit!,
                      style: TextStyle(
                        color: palette.faint,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

final class _LabeledSelect extends StatelessWidget {
  const _LabeledSelect({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 5),
        OriginalFieldSurface(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          child: OriginalPressable(
            onPressed: onPressed,
            semanticLabel: 'تغییر دسته',
            borderRadius: BorderRadius.circular(
              OriginalDesignTokens.fieldRadius,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: palette.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: palette.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

final class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 10),
      child: Column(
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.muted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.faint,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

final class _DebtRow extends StatelessWidget {
  const _DebtRow({
    required this.debt,
    required this.paymentController,
    required this.paymentOpen,
    required this.onTogglePayment,
    required this.onApplyPayment,
    required this.onDelete,
  });

  final Debt debt;
  final TextEditingController paymentController;
  final bool paymentOpen;
  final VoidCallback onTogglePayment;
  final VoidCallback onApplyPayment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return _ObjectSurface(
      settled: debt.settled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  debt.title,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Badge(
                label: debt.settled ? 'تسویه‌شده' : 'بدهی',
                color: debt.settled ? palette.income : palette.amber,
                background: debt.settled
                    ? palette.incomeSoft
                    : palette.amberSoft,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'پرداخت‌شده ${FinancePreviewMath.money(debt.paid)} '
            'از ${FinancePreviewMath.money(debt.total)} تومان',
            style: TextStyle(
              color: palette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 9),
          _ProgressBar(progress: debt.progressForChart, settled: debt.settled),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              if (!debt.settled)
                _MiniButton(
                  label: paymentOpen ? 'بستن' : 'ثبت پرداخت',
                  onPressed: onTogglePayment,
                  semanticLabel: 'ثبت پرداخت برای ${debt.title}',
                ),
              _MiniButton(
                label: 'حذف',
                muted: true,
                onPressed: onDelete,
                semanticLabel: 'حذف بدهی ${debt.title}',
              ),
            ],
          ),
          if (paymentOpen) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OriginalTextField(
                    controller: paymentController,
                    hintText: 'مبلغ پرداخت‌شده',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const <TextInputFormatter>[
                      MoneyInputFormatter(),
                    ],
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    onSubmitted: (_) => onApplyPayment(),
                  ),
                ),
                const SizedBox(width: 7),
                OriginalPrimaryButton(
                  compact: true,
                  label: 'ثبت',
                  onPressed: onApplyPayment,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

final class _InstallmentRow extends StatelessWidget {
  const _InstallmentRow({
    required this.installment,
    required this.onPay,
    required this.onDelete,
  });

  final InstallmentPlan installment;
  final VoidCallback? onPay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return _ObjectSurface(
      settled: installment.settled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  installment.title,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Badge(
                label: installment.settled ? 'تسویه‌شده' : 'قسط',
                color: installment.settled ? palette.income : palette.violet,
                background: installment.settled
                    ? palette.incomeSoft
                    : palette.violetSoft,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${FinancePreviewMath.fa(installment.paidCount)} از '
            '${FinancePreviewMath.fa(installment.installmentCount)} قسط پرداخت شده',
            style: TextStyle(
              color: palette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'مانده: ${FinancePreviewMath.money(installment.remaining)} تومان',
            style: TextStyle(
              color: palette.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          _ProgressBar(
            progress: installment.progressForChart,
            settled: installment.settled,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              if (!installment.settled)
                _MiniButton(
                  label: 'پرداخت یک قسط',
                  onPressed: onPay,
                  semanticLabel: 'پرداخت یک قسط برای ${installment.title}',
                ),
              _MiniButton(
                label: 'حذف',
                muted: true,
                onPressed: onDelete,
                semanticLabel: 'حذف قسط ${installment.title}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _ObjectSurface extends StatelessWidget {
  const _ObjectSurface({required this.child, required this.settled});

  final Widget child;
  final bool settled;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.inner,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: settled ? palette.income.withValues(alpha: .24) : palette.line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: child,
      ),
    );
  }
}

final class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

final class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.settled});

  final double progress;
  final bool settled;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: ColoredBox(color: palette.track)),
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: settled ? palette.income : null,
                      gradient: settled
                          ? null
                          : LinearGradient(
                              colors: <Color>[palette.accent, palette.accent2],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onPressed,
    required this.semanticLabel,
    this.muted = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return OriginalPressable(
      onPressed: onPressed,
      pressedScale: .95,
      semanticLabel: semanticLabel,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: muted ? Colors.transparent : palette.accentSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: muted ? palette.muted : palette.accent,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

final class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.showDivider,
    required this.onDelete,
  });

  final FinanceTransaction transaction;
  final bool showDivider;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final color = transaction.isIncome ? palette.income : palette.expense;
    final background = transaction.isIncome
        ? palette.incomeSoft
        : palette.expenseSoft;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: palette.line))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        child: Row(
          children: <Widget>[
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                transaction.isIncome
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
                size: 17,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.category} · '
                    '${FinancePreviewMath.jalaliShort(transaction.occurredAtUtc.toLocal())}',
                    style: TextStyle(
                      color: palette.faint,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${transaction.isIncome ? '+' : '−'}'
              '${FinancePreviewMath.money(transaction.amount)}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 7),
            OriginalPressable(
              onPressed: onDelete,
              semanticLabel: 'حذف تراکنش',
              pressedScale: .92,
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                width: 31,
                height: 31,
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: palette.faint,
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _OutOfRangeNotice extends StatelessWidget {
  const _OutOfRangeNotice();

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Padding(
      key: const ValueKey<String>('finance-out-of-range'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'مجموع مبالغ از محدوده قابل نمایش بیشتر است.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
