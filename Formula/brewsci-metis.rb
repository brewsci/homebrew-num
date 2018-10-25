class BrewsciMetis < Formula
  desc "Serial programs that partition graphs and order matrices"
  homepage "http://glaros.dtc.umn.edu/gkhome/views/metis"
  url "http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz"
  sha256 "76faebe03f6c963127dbb73c13eab58c9a3faeae48779f049066a21c087c5db2"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    cellar :any_skip_relocation
    sha256 "f6cdb521d777b67c283687573de7c6f4771ee3a6cf04a455201dc6801dcb1bce" => :sierra
    sha256 "e6fac202c1e981a49c93a6b8f0b569eea1f8f86ddafc161acb4959d9e4c27c28" => :x86_64_linux
  end

  keg_only "metis is provided by homebrew/core"

  option "with-openmp", "Enable OpenMP multithreading"

  depends_on "cmake" => :build
  depends_on "gcc" if build.with? "openmp"

  fails_with :clang if build.with? "openmp"

  def install
    cmake_args = std_cmake_args
    cmake_args << "-DSHARED=ON" << "-DGKLIB_PATH=../GKlib"
    if build.with? "openmp"
      cmake_args << "-DOPENMP=ON" << "-DOpenMP_C_FLAGS=-fopenmp" << "-DOpenMP_CXX_FLAGS=-fopenmp" << "-DOpenMP_CXX_LIB_NAMES=gomp"
    end
    cd "build" do
      system "cmake", "..", *cmake_args
      system "make", "install"
    end

    pkgshare.install "graphs"
    doc.install "manual"
  end

  test do
    ["4elt", "copter2", "mdual"].each do |g|
      cp pkgshare/"graphs/#{g}.graph", testpath
      system "#{bin}/graphchk", "#{g}.graph"
      system "#{bin}/gpmetis", "#{g}.graph", "2"
      system "#{bin}/ndmetis", "#{g}.graph"
    end
    cp [pkgshare/"graphs/test.mgraph", pkgshare/"graphs/metis.mesh"], testpath
    system "#{bin}/gpmetis", "test.mgraph", "2"
    system "#{bin}/mpmetis", "metis.mesh", "2"
  end
end
