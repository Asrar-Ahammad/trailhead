double parseTrackingWeight(String input) {
  final weight = double.tryParse(input.trim());
  if (weight == null || !weight.isFinite || weight < 20 || weight > 300) {
    throw const FormatException('Enter a valid weight between 20–300 kg');
  }
  return weight;
}
