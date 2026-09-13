import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MinimalistVisualizer extends StatelessWidget {
  final int? albumId;
  final bool isPlaying;
  final double size;
  final Color glowColor;

  /// Factor de escala base (estado "Pausa").
  ///
  /// Reduce el tamaño resultante multiplicando el tamaño que recibe por este
  /// factor. Con `0.75` la animación se muestra a 3/4 (25% menor) del tamaño
  /// original. Para cambiar el tamaño en pausa, edita este valor:
  ///   - Más grande  -> aumentar (p. ej. `0.9`)
  ///   - Más pequeño -> disminuir (p. ej. `0.5`)
  static const double pausedSizeFactor = 0.75;

  /// Incremento aplicado al pasar de "Pausa" a "Reproducir". Aumenta el
  /// tamaño un 25% (1/4) respecto al de pausa. Para ajustarlo, edita este
  /// valor: `1.25` aumenta 1/4, `1.5` aumentaría la mitad, `1.0` lo deja igual.
  static const double playingGrowth = 1.25;

  /// Factor de redondez de las esquinas. Cuanto mayor, más suaves/curvos.
  /// Usa `1.0` para muy redondeado o `0.4` para esquinas casi cuadradas.
  static const double cornerRoundness = 0.75;

  /// Duración (en ms) de la transición de tamaño al reproducir/pausar. Para
  /// que sea más lenta o rápida, cambia este valor.
  static const double sizeAnimationMs = 500;

  const MinimalistVisualizer({
    super.key,
    this.albumId,
    this.isPlaying = false,
    this.size = 260,
    this.glowColor = const Color(0xFF6D28D9),
  });

  @override
  Widget build(BuildContext context) {
    // Tamaño de referencia: el de "Reproducir" (el mayor). Para "Pausa" se
    // escala hacia abajo con una animación suave, evitando relayouts y
    // recargas de la portada en cada frame.
    final playingSize = size * pausedSizeFactor * playingGrowth;
    const pauseScale = 1.0 / playingGrowth; // 0.8 => 25% menor en pausa

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: isPlaying ? 1.0 : pauseScale),
        duration: Duration(milliseconds: sizeAnimationMs.round()),
        curve: Curves.easeInOutCubic,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: SizedBox(
            width: playingSize,
            height: playingSize,
            child: child,
          ),
        ),
        child: _buildArtwork(playingSize),
      ),
    );
  }

  Widget _buildArtwork(double scaledSize) {
    // La resolución de la portada se solicita en un tamaño mucho mayor al
    // mostrado (downscaling agresivo): se pide a alta resolución y se dibuja
    // a menor tamaño, quedando nítida en lugar de ampliada/borrosa.
    final requestedRes = (scaledSize * 3.0).round().clamp(512, 4096);

    final outerPadding = (scaledSize * 0.035).clamp(8.0, 14.0);
    final artSize = scaledSize - outerPadding * 2;
    // El widget ocupa exactamente el área disponible. Antes se le asignaba un
    // tamaño menor que el contenedor y `BoxFit.cover`, por lo que las portadas
    // rectangulares se recortaban y las cuadradas podían quedar desalineadas.
    final displayRes = artSize;
    final radius =
        (artSize * 0.075 * cornerRoundness).clamp(4.0, 16.0);

    // Ancho del anillo de definición. El recorte de la imagen usa su mismo
    // radio descontando el borde, para que las esquinas sigan exactamente el
    // contorno del cuadro de la animación.
    const frameBorder = 1.2;
    final imageRadius = (radius - frameBorder).clamp(3.0, 15.0);

    return Padding(
      padding: EdgeInsets.all(outerPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            // Resplandor exterior suave (glow)
            BoxShadow(
              color: glowColor.withAlpha(75),
              blurRadius: 40,
              spreadRadius: 4,
              offset: const Offset(0, 6),
            ),
            // Sombra de profundidad para definir el borde
            BoxShadow(
              color: Colors.black.withAlpha(140),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
          // Anillo de definición que hace que el recorte de esquinas
          // se vea limpio y no "comido" por la sombra.
          border: Border.all(
            color: Colors.white.withAlpha(20),
            width: frameBorder,
          ),
        ),
        child: ClipRRect(
          // La imagen sigue el mismo contorno del cuadro: mismo radio
          // descontando el anillo, con antialiasing en las esquinas.
          borderRadius: BorderRadius.circular(imageRadius),
          clipBehavior: Clip.antiAlias,
          child: ColoredBox(
            color: const Color(0xFF111111),
            child: albumId != null
                ? QueryArtworkWidget(
                    id: albumId!,
                    type: ArtworkType.ALBUM,
                    size: requestedRes,
                    quality: 100,
                    // Conserva toda la portada; las bandas sobrantes usan el
                    // fondo del visualizador en vez de ampliar y recortar.
                    artworkFit: BoxFit.contain,
                    artworkWidth: displayRes,
                    artworkHeight: displayRes,
                    artworkQuality: FilterQuality.high,
                    artworkScale: 1.0,
                    artworkBorder: BorderRadius.zero,
                    keepOldArtwork: true,
                    nullArtworkWidget: _defaultArt(artSize),
                  )
                : _defaultArt(artSize),
          ),
        ),
      ),
    );
  }

  Widget _defaultArt(double side) => Container(
        color: const Color(0xFF1C1C1C),
        alignment: Alignment.center,
        child: Icon(Icons.music_note_rounded,
            color: Colors.white54, size: side * 0.42),
      );
}
