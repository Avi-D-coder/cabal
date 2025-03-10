#!/bin/sh
set -ex

. ./travis-common.sh

if [ "$GHCVER" = "none" ]; then
    travis_retry sudo add-apt-repository -y ppa:hvr/ghc
    travis_retry sudo apt-get update
    travis_retry sudo apt-get install --force-yes ghc-$GHCVER
fi

if [ -z ${STACK_CONFIG+x} ]; then
    if [ "$TRAVIS_OS_NAME" = "linux" ]; then
        travis_retry sudo add-apt-repository -y ppa:hvr/ghc
        travis_retry sudo apt-get update
        travis_retry sudo apt-get install --force-yes cabal-install-2.4 ghc-$GHCVER-prof ghc-$GHCVER-dyn
        if [ "x$TEST_OTHER_VERSIONS" = "xYES" ]; then travis_retry sudo apt-get install --force-yes ghc-7.0.4-prof ghc-7.0.4-dyn ghc-7.2.2-prof ghc-7.2.2-dyn ghc-head-prof ghc-head-dyn; fi

        if [ "$SCRIPT" = "meta" ]; then
            # change to /tmp so cabal.project doesn't affect new-install
            cabal v2-update
            (cd /tmp && cabal v2-install alex --constraint='alex ^>= 3.2.5' --overwrite=always)
            (cd /tmp && cabal v2-install happy --constraint='happy ^>= 1.19.9' --overwrite=always)
        fi

    elif [ "$TRAVIS_OS_NAME" = "osx" ]; then

        case $GHCVER in
            8.0.2)
                GHCURL=http://downloads.haskell.org/~ghc/8.0.2/ghc-8.0.2-x86_64-apple-darwin.tar.xz;
                GHCXZ=YES
                ;;
            8.0.1)
                GHCURL=http://downloads.haskell.org/~ghc/8.0.1/ghc-8.0.1-x86_64-apple-darwin.tar.xz;
                GHCXZ=YES
                ;;
            7.10.3)
                GHCURL=http://downloads.haskell.org/~ghc/7.10.3/ghc-7.10.3b-x86_64-apple-darwin.tar.xz
                GHCXZ=YES
                ;;
            7.8.4)
                GHCURL=https://www.haskell.org/ghc/dist/7.8.4/ghc-7.8.4-x86_64-apple-darwin.tar.xz
                GHCXZ=YES
                ;;
            7.6.3)
                GHCURL=https://www.haskell.org/ghc/dist/7.6.3/ghc-7.6.3-x86_64-apple-darwin.tar.bz2
                ;;
            7.4.2)
                GHCURL=https://www.haskell.org/ghc/dist/7.4.2/ghc-7.4.2-x86_64-apple-darwin.tar.bz2
                ;;
            *)
                echo "Unknown GHC: $GHCVER"
                false
                ;;
        esac

        travis_retry curl -OL $GHCURL
        if [ "$GHCXZ" = "YES" ]; then
            tar -xJf ghc-*.tar.*;
        else
            tar -xjf ghc-*.tar.*;
        fi

        cd ghc-*;
        ./configure --prefix=$HOME/.ghc-install/$GHCVER
        make install;
        cd ..;

        mkdir "${HOME}/bin"
        travis_retry curl -L https://downloads.haskell.org/~cabal/cabal-install-2.4.0.0/cabal-install-2.4.0.0-x86_64-apple-darwin-sierra.tar.gz | tar xzO > "${HOME}/bin/cabal"
        chmod a+x "${HOME}/bin/cabal"
        "${HOME}/bin/cabal" --version

    else
        echo "Not linux or osx: $TRAVIS_OS_NAME"
        false
    fi

else # Stack-based builds
    mkdir -p ~/.local/bin
    travis_retry curl -L https://www.stackage.org/stack/linux-x86_64 \
        | tar xz --wildcards --strip-components=1 -C ~/.local/bin '*/stack'
    ~/.local/bin/stack --version
    ~/.local/bin/stack setup --stack-yaml "$STACK_CONFIG"

fi

git version
