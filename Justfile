dev:
  bundle exec jekyll serve

build:
  bundle exec jekyll build

test:
  bundle exec rspec

docker-image:
  docker build -t rebble-dev .

docker-dev:
  docker run --rm -it -p 4000:4000 -v "$PWD":/site -w /site rebble-dev \
    bundle exec jekyll serve --host 0.0.0.0 --port 4000

docker-build:
  docker run --rm -v "$PWD":/site -w /site rebble-dev bundle exec jekyll build
