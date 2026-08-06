/// Which meal is "now" based on the device's local time, and which recipe
/// categories are relevant to surface for it on Home. Boundaries and the
/// adjacent-category choices are a judgment call (not specified by product):
/// breakfast/lunch/dinner map to what was asked for; the late-night hours
/// and the standalone snack window both fall back to a snack-leaning mix
/// since there's no dedicated "late night" category in the app.
class MealWindow {
  final String label;
  final List<String> categories;

  const MealWindow(this.label, this.categories);

  factory MealWindow.forTime(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 11) {
      return const MealWindow('Breakfast', ['Breakfast', 'Snack', 'Drink']);
    }
    if (hour >= 11 && hour < 15) {
      return const MealWindow('Lunch', ['Lunch', 'Dinner', 'Drink']);
    }
    if (hour >= 18 && hour < 22) {
      return const MealWindow('Dinner', ['Lunch', 'Dinner', 'Dessert', 'Drink']);
    }
    // 15:00-17:59 (afternoon snack) and 22:00-4:59 (late night) both land
    // here — neither was specified, snack is the closest fit for both.
    return const MealWindow('Snack', ['Snack', 'Dessert', 'Drink']);
  }
}
