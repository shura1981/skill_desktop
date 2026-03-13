[Desktop Entry]
Version=${DESKTOP_VERSION}
Name=${APP_NAME}
Comment=${APP_COMMENT}
Exec=/opt/${APP_EXEC}/${APP_EXEC} %u
Icon=${APP_EXEC}
Terminal=false
Type=Application
Categories=${CATEGORIES}
StartupWMClass=${APP_ID}
Actions=new-window;

[Desktop Action new-window]
Name=Nueva ventana
Exec=/opt/${APP_EXEC}/${APP_EXEC}
