FROM librecores/ci-osstools:2018.1-rc1

# make sources available in docker image
RUN mkdir -p /src
ADD . /src
ENV COCOTB=/src
WORKDIR /src

# Install dependencies
RUN pip install coverage
RUN pip install xunitparser

# Run build and test
RUN make -C /src test
