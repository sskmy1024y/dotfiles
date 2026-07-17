## =============================
# * zsh内で使用する関数群
## =============================

# estimate distribution name
linux_distribution() {
  if [ -f /etc/debian_version ]; then
    if [ "$(awk -F= '/DISTRIB_ID/ {print $2}' /etc/lsb-release 2>/dev/null)" = "Ubuntu" ]; then
      echo ubuntu
    else
      echo debian
    fi
  elif [ -f /etc/arch-release ]; then
    echo archlinux
  elif [[ -d /system/app/ && -d /system/priv-app ]]; then
    echo android
  else
    echo unkown_linux
  fi
}

# estimate os
detect_os() {
  case "$(uname -s)" in
    Linux|GNU*)
      linux_distribution ;;
    Darwin)
      echo darwin ;;
    Windows|CYGWIN*|MSYS*|MINGW*)
      echo windows ;;
    *)
      echo unknown ;;
  esac
}

is_arm_darwin() {
  case $(detect_os) in
    darwin)
      case $(uname -m) in
        arm64)
          echo true ;;
        *)
          echo false ;;
      esac ;;
    *)
      echo false ;;
  esac
}

# check package & return flag
is_exists() {
    which "$1" >/dev/null 2>&1
    return $?
}
