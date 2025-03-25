import 'package:intl/intl.dart';

class EnergyData {
final List<EnergyUsage> monthlyUsages;
final double solarPanelWatts;
final double solarBatteryKwh;
final double gridKwh;

EnergyData({
    required this.monthlyUsages,
    required this.solarPanelWatts,
    required this.solarBatteryKwh,
    required this.gridKwh,
});

double get totalUsedKwh {
    return monthlyUsages.fold(0, (sum, item) => sum + item.kwh);
}
}

class EnergyUsage {
final DateTime date;
final double kwh;

EnergyUsage({required this.date, required this.kwh});

String get monthYear {
    return DateFormat.MMMM('en_US').format(date);
}
}