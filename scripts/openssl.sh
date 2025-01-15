OPENSSL_LIB_PATH=$(find / -name 'libssl.so*' 2>/dev/null | head -n 1)
OPENSSL_LIB_DIR=$(dirname "$OPENSSL_LIB_PATH")
OPENSSL_INCLUDE_PATH=$(find /usr -name 'ssl.h' 2>/dev/null | grep -v '/node/' | head -n 1)
OPENSSL_INCLUDE_DIR=$(dirname "$OPENSSL_INCLUDE_PATH")
export OPENSSL_STATIC=1
export OPENSSL_LIB_DIR="$OPENSSL_LIB_DIR"
export OPENSSL_INCLUDE_DIR="$OPENSSL_INCLUDE_DIR"
