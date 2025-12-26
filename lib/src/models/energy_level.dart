enum EnergyLevel {
  low('Low Energy', 'Take it easy today'),
  medium('Balanced', 'Ready for a moderate challenge'),
  high('High Energy', 'Bring on the intensity!');

  final String displayName;
  final String description;
  const EnergyLevel(this.displayName, this.description);
}
