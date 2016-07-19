JAVA_VERSION=1.8.0_92
export JAVA_HOME="$(/usr/libexec/java_home -v $JAVA_VERSION)"

GRADLE_VERSION=$(gradle --version | awk '/^Gradle/ {print $2}')
export GRADLE_HOME="/opt/boxen/homebrew/Cellar/gradle/$GRADLE_VERSION/libexec"
