# Para usar una dylib (Librería Dinámica) en Swift:
#
# 1. Compilación: Necesitamos tres flags:
#    -I: Indica dónde está el .swiftmodule (para que el 'import' funcione).
#    -L: Indica la ruta donde el linker debe buscar la librería física.
#    -l: Indica el nombre de la lib (sin prefijo 'lib' ni extensión '.dylib').
#        Ej: -lMiniTests busca un archivo llamado libMiniTests.dylib.
#
# 2. Ejecución: Aunque compile, el binario fallará al arrancar si no sabe
#    dónde "vive" la dylib, ya que macOS no la busca en rutas arbitrarias.
#
#    Para solucionarlo, la lib debe compilarse con un ID de instalación:
#    -Xlinker -install_name -Xlinker "@rpath/libMiniTests.dylib"
#
#    Y el binario que la usa debe definir ese @rpath en su propia compilación:
#    -Xlinker -rpath -Xlinker "/ruta/a/tus/dotfiles"
#
# COMANDO PARA CREAR LA LIB:
swiftc -emit-library -emit-module src.swift \
  -module-name MiniTests \
  -o libMiniTests.dylib \
  -Xlinker -install_name -Xlinker "@rpath/libMiniTests.dylib"
