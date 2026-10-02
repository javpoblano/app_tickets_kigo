import 'package:flutter/widgets.dart';

/// Tokens del sistema de diseño Kigo para la app ED-Operador.
///
/// Centraliza los valores primitivos (paleta de color, espaciados, radios y
/// duraciones) que consumen el tema y los componentes de la UI.
abstract final class AppColors {
  /// Naranja de marca Kigo (Kigo 500). Es el `primaryColor` del tema.
  static const Color kigo500 = Color(0xFFFF6900);

  /// Naranja claro para el inicio del degradado del botón primario.
  static const Color kigo400 = Color(0xFFFF8848);

  /// Naranja tenue (Kigo 300) para acentos sutiles.
  static const Color kigo300 = Color(0xFFFFCBA4);

  /// Fondo cálido de las pantallas (Umbral 50).
  static const Color background = Color(0xFFFEF9F8);

  /// Fondo por defecto de los campos de texto (Umbral 100).
  static const Color umbral100 = Color(0xFFF6EEED);

  /// Borde por defecto de los campos de texto (Umbral 200).
  static const Color umbral200 = Color(0xFFE9DEDD);

  /// Texto principal (Neutral 900).
  static const Color neutral900 = Color(0xFF171717);

  /// Borde neutro del botón secundario (Neutral 200).
  static const Color neutral200 = Color(0xFFE5E5E5);

  /// Texto de ayuda y secundario (Slate 500).
  static const Color slate500 = Color(0xFF62748E);

  /// Texto de placeholder (Slate 400).
  static const Color slate400 = Color(0xFF90A1B9);

  /// Verde de éxito (Green 600).
  static const Color green600 = Color(0xFF00A63E);

  /// Verde claro (Green 400).
  static const Color green400 = Color(0xFF66BB6A);

  /// Verde tenue (Green 100) para fondos de estado de éxito.
  static const Color green100 = Color(0xFFDCFCE7);

  /// Rojo de error (Red 500).
  static const Color red500 = Color(0xFFFB2C36);

  /// Amarillo de advertencia (Yellow 50).
  static const Color yellow50 = Color(0xFFFEFCE8);

  /// Borde del banner de advertencia (Yellow 100).
  static const Color yellow100 = Color(0xFFFEF9C2);

  /// Blanco puro (superficies y texto sobre naranja).
  static const Color white = Color(0xFFFFFFFF);

  /// Splash de las superficies tocables (naranja Kigo al 12%).
  static const Color splash = Color(0x1FFF6900);

  /// Highlight de las superficies tocables (naranja Kigo al 6%).
  static const Color highlight = Color(0x0FFF6900);

  /// Degradado del botón primario (intención / naranja).
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kigo400, kigo500],
  );

  /// Degradado del botón transaccional (dinero / verde).
  static const LinearGradient moneyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [green400, green600],
  );
}

/// Escala de espaciados en puntos lógicos, alineada a la rejilla de 4 pt.
abstract final class AppSpacing {
  /// 4 pt — separación icono-etiqueta.
  static const double micro = 4;

  /// 8 pt — separaciones en línea entre elementos.
  static const double xs = 8;

  /// 12 pt — separación entre tarjetas.
  static const double sm = 12;

  /// 16 pt — padding interno de tarjetas.
  static const double md = 16;

  /// 20 pt — márgenes horizontales de pantalla.
  static const double lg = 20;

  /// 24 pt — separación entre secciones.
  static const double xl = 24;

  /// 32 pt — áreas hero.
  static const double xxl = 32;
}

/// Radios de borde en puntos lógicos.
abstract final class AppRadii {
  /// 10 pt — campos de texto.
  static const double input = 10;

  /// 12 pt — tarjetas de aviso/info.
  static const double infoCard = 12;

  /// 14 pt — tarjetas y botones.
  static const double button = 14;

  /// 14 pt — tarjetas de contenido.
  static const double card = 14;

  /// 25 pt — variante píldora.
  static const double pill = 25;
}

/// Duraciones de animación del sistema de movimiento Kigo.
abstract final class AppDurations {
  /// 150 ms — crossfade skeleton → contenido.
  static const Duration fast = Duration(milliseconds: 150);

  /// 200 ms — transiciones de pago/resultado.
  static const Duration medium = Duration(milliseconds: 200);

  /// 250 ms — apertura de bottom sheets.
  static const Duration slow = Duration(milliseconds: 250);
}

/// Dimensiones de componentes interactivos.
abstract final class AppSizes {
  /// Altura fija de los botones CTA (46 pt).
  static const double ctaHeight = 46;

  /// Altura de los campos de texto.
  static const double inputHeight = 48;

  /// Área mínima de toque accesible.
  static const double minTapTarget = 44;
}

/// URL del icono oficial de Kigo (PNG).
const String kigoIconUrl =
    'https://raw.githubusercontent.com/jesusgarcia-kigo/kigo-design-assets/main/logos/Kigo_Icon.png';
