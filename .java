JAVA_VERSION=1.8.0_121
case "$OSTYPE" in
  linux*)
    command -v javac && export JAVA_HOME="$(dirname $(dirname $(readlink -e $(command -v javac))))"
    ;;
  darwin*)
    export JAVA_HOME="$(/usr/libexec/java_home -v $JAVA_VERSION)"
    GRADLE_VERSION=$(gradle --version | awk '/^Gradle/ {print $2}')
    export GRADLE_HOME="/opt/boxen/homebrew/Cellar/gradle/$GRADLE_VERSION/libexec"
    ;;
  *)
    echo "Unknown OS: $OSTYPE"
    ;;
esac

