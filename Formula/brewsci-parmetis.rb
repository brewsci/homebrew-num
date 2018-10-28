class BrewsciParmetis < Formula
  desc "MPI library for graph partitioning and fill-reducing orderings"
  homepage "http://glaros.dtc.umn.edu/gkhome/metis/parmetis/overview"
  url "http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz"
  sha256 "f2d9a231b7cf97f1fee6e8c9663113ebf6c240d407d3c118c55b3633d6be6e5f"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    cellar :any
    sha256 "c0b729a786c24bde8d56e80b0303d0ce67bbcb8c0da5ed45807bde7d29f66922" => :sierra
    sha256 "c0f0013f82d85cf22e97f82e9c18ad85227993e52d88af7e600946239de4bede" => :x86_64_linux
  end

  keg_only "formulae in brewsci/num are keg only"

  depends_on "cmake" => :build
  depends_on "open-mpi"

  def install
    system "make", "config", "prefix=#{prefix}", "shared=1"
    system "make", "install"
    pkgshare.install "Graphs" # Sample data for test
  end

  test do
    system "mpirun", "#{bin}/ptest", "#{pkgshare}/Graphs/rotor.graph"
  end
end
