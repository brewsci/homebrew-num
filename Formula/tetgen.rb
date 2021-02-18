class Tetgen < Formula
  desc "Quality Tetrahedral Mesh Generator and a 3D Delaunay Triangulator"
  homepage "http://tetgen.org/"
  url "http://www.tetgen.org/1.5/src/tetgen1.5.1.tar.gz"
  sha256 "e46a4434a3e7c00044c8f4f167e18b6f4a85be7d22838c8f948ce8cc8c01b850"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    sha256 cellar: :any_skip_relocation, sierra:       "15806b7803730d5ff1e4f62e3c2622cf5125f62d452217d84b730b6f9c24a716"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "c3bd89a77769edf75686ccb15ab35bda3b61bd0e64261ce1c86575ebb565578d"
  end

  depends_on "cmake" => :build

  resource "manual" do
    url "http://www.tetgen.org/1.5/doc/manual/manual.pdf"
    sha256 "ce71e755c33dc518b1a3bc376fb860c0659e7e14b18e4d9798edcbda05a24eca"
  end

  def install
    mkdir "build" do
      system "cmake", "..", *std_cmake_args
      system "make"
      bin.install "tetgen"
      lib.install "libtet.a"
      include.install buildpath/"tetgen.h"
      resource("manual").stage do
        doc.install "manual.pdf"
      end
      pkgshare.install buildpath/"example.poly"
    end
  end

  test do
    cp pkgshare/"example.poly", testpath
    output = shell_output("#{bin}/tetgen -pq1.2V example.poly")
    assert_match /[Ss]tatistics/, output, "Missing statistics in output"
    assert_match /[Hh]istogram/, output, "Missing histogram in output"
    assert_match /seconds/, output, "Missing timings in output"
    outfile_suffixes = %w[node ele face edge]
    outfile_suffixes.each do |suff|
      assert_predicate testpath/"example.1.#{suff}", :exist?
      rm testpath/"example.1.#{suff}"
    end
    cp testpath/"example.poly", testpath/"example.node"
    system "#{bin}/tetgen", testpath/"example.node"
    outfile_suffixes -= ["edge"]
    outfile_suffixes.each do |suff|
      assert_predicate testpath/"example.1.#{suff}", :exist?
    end
  end
end
