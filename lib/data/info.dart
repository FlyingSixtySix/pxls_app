class Info {
  final int width;
  final int height;
  final List<PaletteColor> palette;

  const Info({
    required this.width,
    required this.height,
    required this.palette,
  });

  factory Info.fromJson(Map<String, dynamic> json) {
    List<PaletteColor> palette = [];
    for (Map<String, dynamic> entry in json['palette']) {
      palette.add(PaletteColor.fromJson(entry));
    }
    return Info(
      width: json['width'],
      height: json['height'],
      palette: palette,
    );
  }
}

class PaletteColor {
  final String name;
  final String value;

  const PaletteColor({
    required this.name,
    required this.value,
  });

  factory PaletteColor.fromJson(Map<String, dynamic> json) {
    return PaletteColor(name: json['name'], value: json['value']);
  }
}
