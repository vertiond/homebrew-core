class Vertcoin < Formula
  desc "Decentralized, peer to peer payment network"
  homepage "https://vertcoin.org/"
  url "https://github.com/vertcoin-project/vertcoin-core/releases/download/v23.2/vertcoin-23.2.tar.gz"
  sha256 "61b4dc289898407d4522e0c48ef2aa38922fc35b925c0a760921bac648d1a60d"
  license "MIT"
  head "https://github.com/vertcoin-project/vertcoin-core.git", branch: "master"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  # berkeley db should be kept at version 4
  # https://github.com/vertcoin-project/vertcoin-core/blob/master/doc/build-osx.md
  # https://github.com/vertcoin-project/vertcoin-core/blob/master/doc/build-unix.md
  depends_on "berkeley-db@4"
  depends_on "boost@1.76"
  depends_on "gmp"
  depends_on "libevent"
  depends_on macos: :catalina # vertcoin requires std::filesystem, which is only supported from Catalina onwards.
  depends_on "miniupnpc"
  depends_on "zeromq"

  uses_from_macos "sqlite"

  on_linux do
    depends_on "util-linux" => :build # for `hexdump`
  end

  fails_with :gcc do
    version "7" # fails with GCC 7.x and earlier
    cause "Requires std::filesystem support"
  end

  def install
    system "./autogen.sh"
    system "./configure", *std_configure_args,
           "--disable-silent-rules",
           "--with-boost-libdir=#{Formula["boost@1.76"].opt_lib}",
           "LDFLAGS=-static-libstdc++"
    system "make", "install"
    pkgshare.install "share/rpcauth"
  end

  service do
    run opt_bin/"vertcoind"
  end

  test do
    # Test that we're using the right version of `berkeley-db`.
    port = free_port
    vertcoind = spawn bin/"vertcoind", "-regtest", "-rpcport=#{port}", "-listen=0", "-datadir=#{testpath}"
    sleep 15
    # This command will fail if we have too new a version.
    system bin/"vertcoin-cli", "-regtest", "-datadir=#{testpath}", "-rpcport=#{port}",
                              "createwallet", "test-wallet", "false", "false", "", "false", "false"
  ensure
    Process.kill "TERM", vertcoind
  end
end
