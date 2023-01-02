class Vertcoin < Formula
  desc "Decentralized, peer to peer payment network"
  homepage "https://vertcoin.org/"
  url "https://github.com/vertcoin-project/vertcoin-core/releases/download/v22.1/vertcoin-22.1.tar.gz"
  sha256 "601d0b6370198c718f102d4c96768c9df668b140aea8def38f4a23bc3afe55af"
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
  depends_on "libevent"
  depends_on macos: :catalina
  depends_on "miniupnpc"
  depends_on "zeromq"
  depends_on "gmp"

  uses_from_macos "sqlite"

  on_linux do
    depends_on "util-linux" => :build # for `hexdump`
  end

  fails_with gcc: "5"

  patch :p0 do
    url "https://github.com/vertcoin-project/packaging/commit/814a78b9bdbfb33a0e881d1ebeae1cd6b6616a3b.patch?full_index=1"
    sha256 "8a9ce8201b42178f33857e6392ab4148f61e7e0e466462e0202517a123111dd7"
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
