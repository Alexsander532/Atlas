#!/bin/bash

# Baixa ou atualiza o Flutter
if cd flutter; then 
  git pull && cd .. 
else 
  git clone https://github.com/flutter/flutter.git -b stable
fi

# Prepara o ambiente e faz o build
flutter/bin/flutter doctor
flutter/bin/flutter build web --release --no-tree-shake-icons

# Copia a configuração de rotas
cp web/vercel.json build/web/vercel.json
