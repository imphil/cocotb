FROM librecores/librecores-ci

# make sources available in docker image
RUN mkdir -p /src
ADD . /src
WORKDIR /src

# Install dependencies
RUN pip install coverage
RUN pip install xunitparser

# Run build and test
RUN make -C /src test

