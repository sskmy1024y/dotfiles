## =============================
# * zsh内で使用する関数群
## =============================

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
    *)
      echo false ;;
  esac
}
