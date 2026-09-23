import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _workLocation = '';
  String _familyLocation = '';
  final _incomeAmountController = TextEditingController();
  String _incomeCurrency = 'USD';
  String _incomeFrequency = 'monthly';
  final List<Map<String, dynamic>> _centers = [
    {'name': 'Current Household', 'icon': 'home', 'color': '#004D60', 'is_default': true},
    {'name': 'Parents', 'icon': 'heart', 'color': '#BA1A1A', 'is_default': true},
    {'name': 'Spouse/Children', 'icon': 'users', 'color': '#005049', 'is_default': true},
    {'name': 'Property', 'icon': 'building', 'color': '#526772', 'is_default': true},
    {'name': 'Charity', 'icon': 'gift', 'color': '#00677F', 'is_default': true},
  ];
  final Set<String> _selectedCenterNames = {};
  final _customCenterController = TextEditingController();
  int _step = 0;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _incomeAmountController.dispose();
    _customCenterController.dispose();
    super.dispose();
  }

  Future<void> _saveOnboarding() async {
    final app = AppScope.of(context);
    final incomeAmount = double.tryParse(_incomeAmountController.text.trim());
    if (incomeAmount == null) {
      setState(() => _error = 'Income amount must be a valid number.');
      return;
    }
    if (_selectedCenterNames.isEmpty) {
      setState(() => _error = 'Select at least one commitment.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final selectedCenters = _centers
        .where((c) => _selectedCenterNames.contains((c['name'] ?? '').toString()))
        .toList();

    final err = await app.saveOnboarding(
      workLocation: _workLocation,
      familyLocation: _familyLocation,
      incomeAmount: incomeAmount,
      incomeCurrency: _incomeCurrency,
      incomeFrequency: _incomeFrequency,
      seedCenters: selectedCenters,
    );
    if (!mounted) return;
    setState(() {
      _error = err;
      _saving = false;
    });
  }

  Widget _frequencyTile({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        height: 158,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.surfaceContainer),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: selected ? Colors.white : AppTheme.onSurfaceVariant.withValues(alpha: 0.45)),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: selected ? Colors.white : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCountryPicker({required bool isWork}) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (context) => _CountryPickerSheet(
        title: isWork ? 'Where do you work?' : 'Where do you send money?',
        selected: isWork ? _workLocation : _familyLocation,
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        if (isWork) {
          _workLocation = selected;
          final currency = _countryCurrencyMap[selected];
          if (currency != null && _currencies.any((c) => c.code == currency)) {
            _incomeCurrency = currency;
          }
        } else {
          _familyLocation = selected;
        }
      });
    }
  }

  Future<void> _openCurrencyPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (context) => _CurrencyPickerSheet(selected: _incomeCurrency),
    );

    if (selected != null && mounted) {
      setState(() => _incomeCurrency = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStepOne = _step == 0;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            children: [
              Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      height: 10,
                      margin: EdgeInsets.only(right: i == 2 ? 0 : 10),
                      decoration: BoxDecoration(
                        color: i <= _step ? AppTheme.primary : AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      _step == 0 ? 'Where is your life?' : _step == 1 ? 'Your Income' : 'Responsibilities',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontSize: isStepOne ? 58 : 38,
                            color: AppTheme.primary,
                            height: 1.0,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _step == 0
                          ? "Let's set the context for your financial journey."
                          : _step == 1
                              ? "What's your monthly fuel?"
                              : 'Who or what do you support?',
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (_step == 0) ...[
                      const _OnboardLabel('WHERE DO YOU WORK?'),
                      const SizedBox(height: 10),
                      _CountryField(
                        value: _workLocation,
                        hint: 'e.g. Dubai, London',
                        icon: Icons.place_outlined,
                        onTap: () => _openCountryPicker(isWork: true),
                      ),
                      const SizedBox(height: 22),
                      const _OnboardLabel('WHERE DO YOU USUALLY SEND MONEY?'),
                      const SizedBox(height: 10),
                      _CountryField(
                        value: _familyLocation,
                        hint: 'e.g. Mumbai, Manila',
                        icon: Icons.favorite_border,
                        onTap: () => _openCountryPicker(isWork: false),
                      ),
                    ] else if (_step == 1) ...[
                      const _OnboardLabel('SALARY AMOUNT'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _incomeAmountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primary),
                              decoration: const InputDecoration(hintText: '0.00'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: _openCurrencyPicker,
                              child: InputDecorator(
                                decoration: const InputDecoration(),
                                child: Row(
                                  children: [
                                    Text(
                                      _currencies.firstWhere((c) => c.code == _incomeCurrency).flag,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _incomeCurrency,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down_rounded),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _OnboardLabel('FREQUENCY'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _frequencyTile(
                              icon: Icons.calendar_month_outlined,
                              label: 'Monthly',
                              selected: _incomeFrequency == 'monthly',
                              onTap: () => setState(() => _incomeFrequency = 'monthly'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _frequencyTile(
                              icon: Icons.sync_alt_rounded,
                              label: 'Bi-weekly',
                              selected: _incomeFrequency == 'bi-weekly',
                              onTap: () => setState(() => _incomeFrequency = 'bi-weekly'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _frequencyTile(
                              icon: Icons.schedule_rounded,
                              label: 'Weekly',
                              selected: _incomeFrequency == 'weekly',
                              onTap: () => setState(() => _incomeFrequency = 'weekly'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _centers.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _centers.removeAt(oldIndex);
                            _centers.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final center = _centers[index];
                          final name = (center['name'] ?? '').toString();
                          final selected = _selectedCenterNames.contains(name);
                          return Container(
                            key: ValueKey(name),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedCenterNames.remove(name);
                                  } else {
                                    _selectedCenterNames.add(name);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.primary : AppTheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                          color: selected ? Colors.white : AppTheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (selected) const Icon(Icons.check_rounded, color: Colors.white, size: 26),
                                    const SizedBox(width: 4),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(
                                        Icons.drag_indicator_rounded,
                                        color: selected ? Colors.white70 : AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, top: 2, bottom: 12),
                        child: Text(
                          'Tip: Tap to select, drag to reorder your priorities.',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _OnboardLabel('ADD CUSTOM RESPONSIBILITY'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customCenterController,
                              decoration: const InputDecoration(hintText: 'e.g. Education, Business, Savings'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 96,
                            child: FilledButton.tonal(
                              onPressed: () {
                                final name = _customCenterController.text.trim();
                                if (name.isEmpty) return;
                                setState(() {
                                  _selectedCenterNames.add(name);
                                  _centers.add({
                                    'name': name,
                                    'icon': 'target',
                                    'color': '#526772',
                                    'is_default': false,
                                  });
                                  _customCenterController.clear();
                                });
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                backgroundColor: AppTheme.tertiaryContainer,
                                foregroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (_step > 0) ...[
                    SizedBox(
                      width: 88,
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => setState(() => _step -= 1),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          backgroundColor: AppTheme.surfaceContainer,
                          side: BorderSide.none,
                        ),
                        child: const Icon(Icons.chevron_left_rounded),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () {
                              if (_step < 2) {
                                setState(() => _step += 1);
                                return;
                              }
                              _saveOnboarding();
                            },
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_step < 2 ? 'Continue' : 'Get Started'),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardLabel extends StatelessWidget {
  const _OnboardLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.onSurfaceVariant,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _CountryField extends StatelessWidget {
  const _CountryField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  final String value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          value.isEmpty ? hint : value,
          style: TextStyle(
            fontSize: 16,
            color: value.isEmpty ? AppTheme.onSurfaceVariant.withValues(alpha: 0.5) : AppTheme.onSurface,
            fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.title, required this.selected});

  final String title;
  final String selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<_CountryOption> _filtered = _countries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _countries
          : _countries.where((c) => c.name.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
                decoration: const InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final country = _filtered[i];
                    final isSelected = country.name == widget.selected;
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : null,
                      leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        country.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                      onTap: () => Navigator.pop(context, country.name),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }
}

const Map<String, String> _countryCurrencyMap = {
  'Afghanistan': 'USD',
  'Albania': 'EUR',
  'Algeria': 'USD',
  'Argentina': 'USD',
  'Australia': 'USD',
  'Austria': 'EUR',
  'Bangladesh': 'USD',
  'Belgium': 'EUR',
  'Brazil': 'USD',
  'Brunei': 'BND',
  'Cambodia': 'KHR',
  'Canada': 'USD',
  'China': 'USD',
  'Colombia': 'USD',
  'Egypt': 'EGP',
  'Ethiopia': 'USD',
  'France': 'EUR',
  'Germany': 'EUR',
  'Ghana': 'USD',
  'Greece': 'EUR',
  'Hong Kong': 'USD',
  'India': 'INR',
  'Indonesia': 'IDR',
  'Iran': 'USD',
  'Iraq': 'USD',
  'Ireland': 'EUR',
  'Israel': 'USD',
  'Italy': 'EUR',
  'Japan': 'USD',
  'Jordan': 'USD',
  'Kenya': 'USD',
  'Kuwait': 'USD',
  'Laos': 'LAK',
  'Lebanon': 'USD',
  'Malaysia': 'MYR',
  'Mexico': 'USD',
  'Morocco': 'USD',
  'Myanmar': 'MMK',
  'Nepal': 'INR',
  'Netherlands': 'EUR',
  'New Zealand': 'USD',
  'Nigeria': 'USD',
  'Norway': 'USD',
  'Oman': 'USD',
  'Pakistan': 'PKR',
  'Philippines': 'PHP',
  'Poland': 'EUR',
  'Portugal': 'EUR',
  'Qatar': 'USD',
  'Romania': 'EUR',
  'Russia': 'USD',
  'Saudi Arabia': 'USD',
  'Singapore': 'SGD',
  'South Africa': 'USD',
  'South Korea': 'USD',
  'Spain': 'EUR',
  'Sri Lanka': 'USD',
  'Sweden': 'USD',
  'Switzerland': 'USD',
  'Taiwan': 'USD',
  'Tanzania': 'USD',
  'Thailand': 'THB',
  'Turkey': 'USD',
  'Uganda': 'USD',
  'Ukraine': 'USD',
  'United Arab Emirates': 'AED',
  'United Kingdom': 'GBP',
  'United States': 'USD',
  'Vietnam': 'VND',
  'Yemen': 'USD',
  'Zimbabwe': 'USD',
};

class _CountryOption {
  const _CountryOption(this.name, this.flag);
  final String name;
  final String flag;
}

const List<_CountryOption> _countries = [
  _CountryOption('Afghanistan', '🇦🇫'),
  _CountryOption('Albania', '🇦🇱'),
  _CountryOption('Algeria', '🇩🇿'),
  _CountryOption('Argentina', '🇦🇷'),
  _CountryOption('Australia', '🇦🇺'),
  _CountryOption('Austria', '🇦🇹'),
  _CountryOption('Bangladesh', '🇧🇩'),
  _CountryOption('Belgium', '🇧🇪'),
  _CountryOption('Brazil', '🇧🇷'),
  _CountryOption('Brunei', '🇧🇳'),
  _CountryOption('Cambodia', '🇰🇭'),
  _CountryOption('Canada', '🇨🇦'),
  _CountryOption('China', '🇨🇳'),
  _CountryOption('Colombia', '🇨🇴'),
  _CountryOption('Egypt', '🇪🇬'),
  _CountryOption('Ethiopia', '🇪🇹'),
  _CountryOption('France', '🇫🇷'),
  _CountryOption('Germany', '🇩🇪'),
  _CountryOption('Ghana', '🇬🇭'),
  _CountryOption('Greece', '🇬🇷'),
  _CountryOption('Hong Kong', '🇭🇰'),
  _CountryOption('India', '🇮🇳'),
  _CountryOption('Indonesia', '🇮🇩'),
  _CountryOption('Iran', '🇮🇷'),
  _CountryOption('Iraq', '🇮🇶'),
  _CountryOption('Ireland', '🇮🇪'),
  _CountryOption('Israel', '🇮🇱'),
  _CountryOption('Italy', '🇮🇹'),
  _CountryOption('Japan', '🇯🇵'),
  _CountryOption('Jordan', '🇯🇴'),
  _CountryOption('Kenya', '🇰🇪'),
  _CountryOption('Kuwait', '🇰🇼'),
  _CountryOption('Laos', '🇱🇦'),
  _CountryOption('Lebanon', '🇱🇧'),
  _CountryOption('Malaysia', '🇲🇾'),
  _CountryOption('Mexico', '🇲🇽'),
  _CountryOption('Morocco', '🇲🇦'),
  _CountryOption('Myanmar', '🇲🇲'),
  _CountryOption('Nepal', '🇳🇵'),
  _CountryOption('Netherlands', '🇳🇱'),
  _CountryOption('New Zealand', '🇳🇿'),
  _CountryOption('Nigeria', '🇳🇬'),
  _CountryOption('Norway', '🇳🇴'),
  _CountryOption('Oman', '🇴🇲'),
  _CountryOption('Pakistan', '🇵🇰'),
  _CountryOption('Philippines', '🇵🇭'),
  _CountryOption('Poland', '🇵🇱'),
  _CountryOption('Portugal', '🇵🇹'),
  _CountryOption('Qatar', '🇶🇦'),
  _CountryOption('Romania', '🇷🇴'),
  _CountryOption('Russia', '🇷🇺'),
  _CountryOption('Saudi Arabia', '🇸🇦'),
  _CountryOption('Singapore', '🇸🇬'),
  _CountryOption('South Africa', '🇿🇦'),
  _CountryOption('South Korea', '🇰🇷'),
  _CountryOption('Spain', '🇪🇸'),
  _CountryOption('Sri Lanka', '🇱🇰'),
  _CountryOption('Sweden', '🇸🇪'),
  _CountryOption('Switzerland', '🇨🇭'),
  _CountryOption('Taiwan', '🇹🇼'),
  _CountryOption('Tanzania', '🇹🇿'),
  _CountryOption('Thailand', '🇹🇭'),
  _CountryOption('Turkey', '🇹🇷'),
  _CountryOption('Uganda', '🇺🇬'),
  _CountryOption('Ukraine', '🇺🇦'),
  _CountryOption('United Arab Emirates', '🇦🇪'),
  _CountryOption('United Kingdom', '🇬🇧'),
  _CountryOption('United States', '🇺🇸'),
  _CountryOption('Vietnam', '🇻🇳'),
  _CountryOption('Yemen', '🇾🇪'),
  _CountryOption('Zimbabwe', '🇿🇼'),
];

class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({required this.selected});
  final String selected;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchController = TextEditingController();
  List<_CurrencyOption> _filtered = _currencies;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _currencies
          : _currencies.where((c) => c.code.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select currency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
                decoration: const InputDecoration(
                  hintText: 'Search currency...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final c = _filtered[i];
                    final isSelected = c.code == widget.selected;
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : null,
                      leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w800)),
                      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                      onTap: () => Navigator.pop(context, c.code),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }
}

class _CurrencyOption {
  const _CurrencyOption(this.code, this.flag);
  final String code;
  final String flag;
}

const List<_CurrencyOption> _currencies = [
  _CurrencyOption('USD', '🇺🇸'),
  _CurrencyOption('EUR', '🇪🇺'),
  _CurrencyOption('GBP', '🇬🇧'),
  _CurrencyOption('AED', '🇦🇪'),
  _CurrencyOption('INR', '🇮🇳'),
  _CurrencyOption('PHP', '🇵🇭'),
  _CurrencyOption('PKR', '🇵🇰'),
  _CurrencyOption('EGP', '🇪🇬'),
  _CurrencyOption('MYR', '🇲🇾'),
  _CurrencyOption('SGD', '🇸🇬'),
  _CurrencyOption('IDR', '🇮🇩'),
  _CurrencyOption('THB', '🇹🇭'),
  _CurrencyOption('VND', '🇻🇳'),
  _CurrencyOption('BND', '🇧🇳'),
  _CurrencyOption('MMK', '🇲🇲'),
  _CurrencyOption('KHR', '🇰🇭'),
  _CurrencyOption('LAK', '🇱🇦'),
];
