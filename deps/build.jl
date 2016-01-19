using BinDeps

@BinDeps.setup

libnlopt = library_dependency("libnlopt", aliases=["libnlopt_cxx", "libnlopt$(WORD_SIZE)"])

provides(AptGet, "libnlopt0", libnlopt)

provides(Sources,URI("http://ab-initio.mit.edu/nlopt/nlopt-2.4.tar.gz"), libnlopt)

nloptname = "nlopt-2.4.1"

usrdir = BinDeps.usrdir(libnlopt)
srcdir = BinDeps.srcdir(libnlopt)
@unix_only begin
   try
     println("Trying to clone to ", srcdir)
     LibGit2.clone("https://github.com/stevengj/nlopt.git", srcdir)
   catch
     try
       println("NLopt clone failed. Trying to update repo.")
       repo = LibGit2.GitRepo(srcdir)
       LibGit2.fetch(repo)
       LibGit2.merge!(repo, fastforward=true)
     catch
       println("Failed to pull nlopt git repo.")
     end
   end
   println(readall(pipeline(`cat $(dirname(@__FILE__))/Makefile.patch`, Cmd(`patch`, dir=srcdir, ignorestatus=true))))
   println("Running autogen.")
   println(success(Cmd(`./autogen.sh --no-configure`, dir=srcdir)))
   println("Cleaning repo.")
   println(readall(Cmd(`make clean`, dir=srcdir)))
   println("Running configure with required extensions.")
   println(success(Cmd(`./configure --enable-shared --enable-maintainer-mode --disable-static --without-guile --without-python --without-octave --without-matlab --prefix=$usrdir`, dir=srcdir)))
end

provides(BuildProcess, 
  (@build_steps begin
    ChangeDirectory(srcdir)
    `make`
    `make install`
  end), libtarget="libnlopt_cxx.la", libnlopt, os = :Unix)

# libdir = BinDeps.libdir(libnlopt)
# 
# extractdir(w) = joinpath(srcdir,"w$w")
# destw(w) = joinpath(libdir,"libnlopt$(w).dll")
# provides(BuildProcess,
# 	(@build_steps begin
# 		FileDownloader("http://ab-initio.mit.edu/nlopt/$(nloptname)-dll32.zip", joinpath(downloadsdir, "$(nloptname)-dll32.zip"))
# 		FileDownloader("http://ab-initio.mit.edu/nlopt/$(nloptname)-dll64.zip", joinpath(downloadsdir, "$(nloptname)-dll64.zip"))
# 		CreateDirectory(srcdir, true)
# 		CreateDirectory(joinpath(srcdir,"w32"), true)
# 		CreateDirectory(joinpath(srcdir,"w64"), true)
# 		FileUnpacker(joinpath(downloadsdir,"$(nloptname)-dll32.zip"), extractdir(32), joinpath(extractdir(32),"matlab"))
# 		FileUnpacker(joinpath(downloadsdir,"$(nloptname)-dll64.zip"), extractdir(64), joinpath(extractdir(64),"matlab"))
# 		CreateDirectory(libdir, true)
# 		@build_steps begin
# 			ChangeDirectory(extractdir(32))
# 			FileRule(destw(32), @build_steps begin
# 				`powershell -Command "cp libnlopt-0.dll $(destw(32))"`
# 				end)
# 		end
# 		@build_steps begin
# 			ChangeDirectory(extractdir(64))
# 			FileRule(destw(64), @build_steps begin
# 				`powershell -Command "cp libnlopt-0.dll $(destw(64))"`
# 				end)
# 		end
# 	end), libnlopt, os = :Windows)
# 
# @windows_only push!(BinDeps.defaults, BuildProcess)

@BinDeps.install Dict(:libnlopt => :libnlopt)

# @windows_only pop!(BinDeps.defaults)