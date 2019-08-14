class Lancelot < Formula
  desc "Large-scale nonlinear optimization"
  homepage "http://www.numerical.rl.ac.uk/lancelot/blurb.html"
  url "https://github.com/ralna/LANCELOT/archive/v2019.08.09.tar.gz"
  sha256 "bf658b0a8ae9ae7bef1dff154b65760415116fb8287082e44661a58daf51d51f"
  head "https://github.com/ralna/LANCELOT.git"

  bottle do
    cellar :any
    sha256 "e8390f9f7c79d6ddb774beedd6a15d2dc479e5a9625d43e45d41aab9b1bde3a1" => :sierra
    sha256 "44e1187f682f046eb0c628168d897accb7d68d7c8673ce37a9a0dcb5c013e172" => :x86_64_linux
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
