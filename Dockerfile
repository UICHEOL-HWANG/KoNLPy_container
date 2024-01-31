FROM ubuntu:latest

ENV LANG=C.UTF-8

ENV MECAB_VERSION mecab-0.996-ko-0.9.2
ENV MECAB_DICT_VERSION mecab-ko-dic-2.1.1-20180720
ENV MECAB_PYTHON_VERSION mecab-python-0.996

# 시스템 업데이트 및 필요한 도구 설치
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata g++ curl \
    autoconf automake libtool git \
    openjdk-8-jdk

ENV JAVA_HOME="/usr/lib/jvm/java-1.8-openjdk"

# Python 설치
RUN apt-get install -y python3-pip python3-dev
RUN cd /usr/local/bin && \
    ln -s /usr/bin/python3 python && \
    ln -s /usr/bin/pip3 pip && \
    pip install --upgrade pip

# 필요하지 않은 파일 제거
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 작업 디렉토리 설정
WORKDIR /app

# 애플리케이션 파일 및 requirements.txt 복사
COPY . /app

# Python 의존성 설치
RUN pip install --no-cache-dir --disable-pip-version-check -r requirements.txt

# Mecab 설치
RUN set -ex \
    && curl -LO https://bitbucket.org/eunjeon/mecab-ko/downloads/${MECAB_VERSION}.tar.gz \
    && tar zxvf ${MECAB_VERSION}.tar.gz \
    && cd ${MECAB_VERSION} \
    && ./configure \
    && make \
    && make check \
    && make install \
    && ldconfig

# Mecab Dictionary 설치
RUN set -ex \
    && curl -LO https://bitbucket.org/eunjeon/mecab-ko-dic/downloads/${MECAB_DICT_VERSION}.tar.gz \
    && tar zxvf ${MECAB_DICT_VERSION}.tar.gz \
    && cd ${MECAB_DICT_VERSION} \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
    && ldconfig

# Mecab Python 설치
RUN set -ex \
    && git clone https://bitbucket.org/eunjeon/${MECAB_PYTHON_VERSION}.git \
    && cd ${MECAB_PYTHON_VERSION} \
    && python setup.py build \
    && python setup.py install

# Jupyter Notebook 설치 및 포트 노출
RUN pip install notebook
EXPOSE 9000

# Jupyter Notebook 실행
CMD ["jupyter", "notebook", "--ip='*'", "--port=9000", "--no-browser", "--NotebookApp.token=''", "--NotebookApp.password=''", "--allow-root"]

