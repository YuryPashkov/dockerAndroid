FROM java:8

ENV DEBIAN_FRONTEND noninteractive
USER root
#FIX problems with fetching jessie back port repositories
RUN echo "deb [check-valid-until=no] http://cdn-fastly.deb.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list
RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
RUN sed -i '/deb http:\/\/deb.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list
RUN apt-get -o Acquire::Check-Valid-Until=false update
# Install dependencies
RUN apt-get install --yes \
        xvfb lib32z1 lib32stdc++6 build-essential \
        libcurl4-openssl-dev libglu1-mesa libxi-dev libxmu-dev \
        libglu1-mesa-dev

# Download and untar SDK
#ENV ANDROID_SDK_URL https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
#RUN curl -L "${ANDROID_SDK_URL}" | tar --no-same-owner -xz -C /usr/local
#ENV ANDROID_HOME /usr/local/android-sdk-linux
#ENV ANDROID_SDK /usr/local/android-sdk-linux
#ENV PATH ${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:$ANDROID_HOME/platform-tools:$PATH

ARG ANDROID_SDK_VERSION=4333796
ENV ANDROID_SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_VERSION}.zip" \
    ANDROID_SDK="/usr/local/android-sdk-linux" \
    ANDROID_HOME="/usr/local/android-sdk-linux"
RUN mkdir -p "$ANDROID_HOME"\
 && cd "$ANDROID_HOME" \
 && curl -o sdk.zip $ANDROID_SDK_URL \
 && unzip sdk.zip \
 && rm sdk.zip 

ENV PATH ${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:$ANDROID_HOME/platform-tools:$PATH

# Install Android SDK components

RUN yes | sdkmanager --verbose \
      'tools' \
      'platform-tools' \
      'build-tools;26.0.3' \
      'build-tools;27.0.0' \
      'build-tools;27.0.1' \
      'build-tools;27.0.2' \
      'build-tools;27.0.3' \
      'build-tools;28.0.3' \
      'build-tools;29.0.0' \
      'build-tools;29.0.2' \
      'build-tools;30.0.0' \
      'build-tools;30.0.1' \
      'platforms;android-25' \
      'platforms;android-26' \
      'platforms;android-27' \
      'platforms;android-28' \
      'platforms;android-29' \
      'platforms;android-30' \
      'extras;android;m2repository' \
      'extras;google;m2repository' \
      'extras;google;google_play_services' \
      'extras;m2repository;com;android;support;constraint;constraint-layout;1.0.0' \
      'extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1' \
      'extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2'

# Support Gradle
ENV TERM dumb

#Add Android SDK License
#RUN yes | $ANDROID_SDK/tools/bin/sdkmanager --licenses
ADD license_accepter.sh /opt/
RUN chmod +x /opt/license_accepter.sh
RUN /opt/license_accepter.sh $ANDROID_HOME

RUN mkdir -p /opt/workspace
WORKDIR /opt/workspace

# Download and install the cloud sdk
RUN wget https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz --no-check-certificate \
    && tar zxvf google-cloud-sdk.tar.gz -C /usr/local \
    && rm google-cloud-sdk.tar.gz \
    && ls -l \
    && /usr/local/google-cloud-sdk/install.sh --usage-reporting=true --path-update=true

# Add gcloud to the path
ENV PATH /usr/local/google-cloud-sdk/bin:$PATH

# Download flutter 
ENV FLUTTER_CHANNEL=stable
ENV FLUTTER_VERSION=1.0.0-${FLUTTER_CHANNEL}

RUN wget --quiet --output-document=flutter.tar.xz https://storage.googleapis.com/flutter_infra/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_v${FLUTTER_VERSION}.tar.xz \
    && tar xf flutter.tar.xz -C /opt \
    && rm flutter.tar.xz

ENV PATH=$PATH:/opt/flutter/bin
ENV FLUTTER_HOME=/opt/flutter
ENV FLUTTER_ROOT=/opt/flutter