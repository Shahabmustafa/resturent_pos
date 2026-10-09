# Financial Reports Module — Spice Garden POS

## Files

```
lib/features/financial_reports/
├── models/
│   └── financial_reports_models.dart     # All data models + state
├── data/
│   └── financial_reports_datasource.dart # Supabase queries
├── providers/
│   ├── financial_reports_provider.dart   # Riverpod providers
│   └── financial_reports_notifier.dart   # StateNotifier logic
├── screens/
│   ├── financial_reports_screen.dart     # Main screen (tabs + header)
│   ├── sales_report_tab.dart             # Tab 1: Sales
│   ├── profit_report_tab.dart            # Tab 2: Profit & Loss
│   ├── product_report_tab.dart           # Tab 3: Products
│   ├── expense_report_tab.dart           # Tab 4: Expenses
│   └── financial_reports_export.dart     # PDF + CSV export
└── widgets/
    ├── report_helpers.dart               # Colors, formatters, shared widgets
    ├── summary_cards.dart                # Top KPI cards
    └── date_filter_bar.dart              # Date filter + custom range picker
```

## Integration Steps

### 1. Add the route (your router file)

```dart
GoRoute(
  path: '/financial-reports',
  builder: (context, state) => const FinancialReportsScreen(),
),
```

### 2. Wire up branchId (financial_reports_provider.dart)

```dart
// Replace this:
const branchId = '';

// With this:
final branch = ref.watch(branchAuthProvider);
final branchId = branch?.branchId ?? '';
```

### 3. pubspec.yaml — required packages

```yaml
dependencies:
  pdf: ^3.10.8
  printing: ^5.12.0
  intl: ^0.19.0
```

### 4. Finish the export buttons (financial_reports_screen.dart)

In `_ExportButton._export()`:

```dart
case 'pdf':
  await exportReportPdf(
    context: context,
    summary: state.summary,
    products: notifier.sortedProducts,
    expenses: state.expenseReports,
    startDate: state.startDate,
    endDate: state.endDate,
    restaurantName: 'Spice Garden', // ya settings se lo
  );

case 'csv':
  final csv = buildReportCsv(
    summary: state.summary,
    products: notifier.sortedProducts,
    expenses: state.expenseReports,
    startDate: state.startDate,
    endDate: state.endDate,
  );
  // On web: use dart:html AnchorElement
  // On desktop: use file_selector saveFile()
```

## Supabase Requirements

### order_items table — add columns if missing:
```sql
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS unit_cost NUMERIC DEFAULT 0;
```
(unit_cost = cost price at time of order — populate from menu_item.cost_price when order is placed)

### supplier_transactions — expense tracking:
Already used for supplier payments. `type = 'payment'` entries count as expenses.

### RLS Policies needed:
```sql
CREATE POLICY "branch users can read orders" ON orders
  FOR SELECT USING (branch_id = auth.jwt() ->> 'branch_id');

CREATE POLICY "branch users can read order_items" ON order_items
  FOR SELECT USING (
    order_id IN (SELECT id FROM orders WHERE branch_id = auth.jwt() ->> 'branch_id')
  );
```

## Features

- ✅ Sales tab: revenue cards, daily trend chart, payment method breakdown
- ✅ Profit & Loss tab: full P&L statement, margin percentages, visual breakdown
- ✅ Products tab: sortable table (revenue/qty/profit), top-5 bar chart, margin colors
- ✅ Expenses tab: category breakdown, visual bar, share percentages  
- ✅ Date filters: Today, Yesterday, This Week, This Month, Last Month, Custom Range
- ✅ PDF export (NotoSans fonts, A4, full report)
- ✅ CSV export (all sections)
- ✅ Error handling + refresh button
- ✅ Loading states
