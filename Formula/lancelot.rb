class Lancelot < Formula
  desc "Large-scale nonlinear optimization"
  homepage "http://www.numerical.rl.ac.uk/lancelot/blurb.html"
  url "http://www.numerical.rl.ac.uk/lancelot/downloads/lancelot.tar.gz"
  version "A-2001-02-27"
  sha256 "a0d25ebdc02b05f62997bdd3dbae1c06b21196cc0fd6b79630d0b157182e060c"

  depends_on "gcc"
  depends_on "tcsh" if OS.linux?

  def install
    mv "unfold.g77", "unwrap"
    chmod 0755, "./unwrap"
    inreplace "unwrap", "/bin/csh", "/usr/bin/env csh"
    system "./unwrap"
    inreplace "instll", "/bin/csh", "/usr/bin/env csh"
    ["instll",
     "lancelot/compil",
     "lancelot/sources/optimizers/makefile",
     "lancelot/sources/sifdec/makefile"].each { |f| inreplace f, "g77", "gfortran" }
    system "./instll", "single", "large"
    system "./instll", "double", "large"
    ["lancelot/lan", "lancelot/sdlan"].each { |f| inreplace f, "/bin/csh", "/usr/bin/env csh" }
    inreplace "lancelot/lan", "g77", "gfortran"
    libexec.install "lancelot"
    %w[lan sdlan sifdec_s sifdec_d].each { |f| bin.install_symlink libexec/"lancelot/#{f}" }
    share.install "sampleproblems"
    doc.install "manual.err"
  end

  def caveats
    "Set the LANDIR environment variable to #{opt_libexec}/lancelot"
  end

  test do
    ENV.append "LANDIR", opt_libexec/"lancelot"
    cp opt_share/"sampleproblems/ALLIN.SIF", testpath
    system "#{bin}/sdlan", "ALLIN"
    system "#{bin}/lan", "-n"
  end
end
