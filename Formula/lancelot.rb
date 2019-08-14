class Lancelot < Formula
  desc "Large-scale nonlinear optimization"
  homepage "http://www.numerical.rl.ac.uk/lancelot/blurb.html"
  url "https://github.com/ralna/LANCELOT/archive/v2019.08.09.tar.gz"
  sha256 "bf658b0a8ae9ae7bef1dff154b65760415116fb8287082e44661a58daf51d51f"
  head "https://github.com/ralna/LANCELOT.git"

  bottle do
    cellar :any
    sha256 "371f5d30bf12c4d8a145349810c622985289b2d3467385461473a20cca1cb69f" => :sierra
    sha256 "2ae28e21e5172371bb09c3ce8f850fffd4b5aab81cd30740bf48b72e7b0a459b" => :x86_64_linux
  end

  depends_on "gcc"
  depends_on "tcsh" if OS.linux?

  def install
    system "make"
    system "make", "PRECISION=single"
    ["bin/lan", "bin/sdlan"].each { |f| inreplace f, "/bin/csh", "/usr/bin/env csh" }
    libexec.install "bin", "objects"
    %w[lan sdlan sifdec_single sifdec_double].each { |f| bin.install_symlink libexec/"bin/#{f}" }
    doc.install "doc/manual.err"
    share.install "sampleproblems", "SPEC.SPC"
  end

  def caveats
    "Set the LANDIR environment variable to #{opt_libexec}"
  end

  test do
    ENV.append "LANDIR", opt_libexec
    cp opt_share/"sampleproblems/ALLIN.SIF", testpath
    system "#{bin}/sdlan", "ALLIN"
    system "#{bin}/lan", "-n"
    system "#{bin}/sdlan", "-s", "ALLIN"
    system "#{bin}/lan", "-s", "-n"
  end
end
