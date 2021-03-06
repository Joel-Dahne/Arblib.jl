using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = true#"--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, ["libarb"], :libarb),
    LibraryProduct(prefix, ["libflint"], :libflint),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/thofma/ArbBuilder/releases/download/6c3738-v2"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    MacOS(:x86_64) => ("$bin_prefix/libarb.v0.0.0-6c3738555d00b8b8b24a1f5e0065ef787432513c.x86_64-apple-darwin14.tar.gz", "ff7997dbb5d7161a5fe498e2e21fc6647b7535d70d553986fa769d89e9767544"),
    Linux(:x86_64, libc=:glibc) => ("$bin_prefix/libarb.v0.0.0-6c3738555d00b8b8b24a1f5e0065ef787432513c.x86_64-linux-gnu.tar.gz", "df511674d095990db432223183a351705b754a5c6b8e2c120e022b13dfece531"),
    Windows(:x86_64) => ("$bin_prefix/libarb.v0.0.0-6c3738555d00b8b8b24a1f5e0065ef787432513c.x86_64-w64-mingw32.tar.gz", "5af9f15b30ae46c4315c5b90a8cff2f26bdb84cc6883141fb213de9488999b32"),
)

dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GMP-v6.1.2-1/build_GMP.v6.1.2.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/MPFR-v4.0.2-1/build_MPFR.v4.0.2.jl",
    "https://github.com/thofma/Flint2Builder/releases/download/ba0cee/build_libflint.v0.0.0-ba0ceed35136a2a43441ab9a9b2e7764e38548ea.jl",
    "https://github.com/thofma/ArbBuilder/releases/download/56ce68/build_libarb.v0.0.0-56ce687ea1ff9a279dc3c8d20f31a4dd09bae6d1.jl",
]

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
dl_info = choose_download(download_info, platform_key_abi())
if dl_info === nothing && unsatisfied
    # If we don't have a compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform (\"$(Sys.MACHINE)\", parsed as \"$(triplet(platform_key_abi()))\") is not supported by this package!")
end

# If we have a download, and we are unsatisfied (or the version we're
# trying to install is not itself installed) then load it up!
if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
    # Download and install binaries
    for dependency in dependencies # We do not check for already installed dependencies
        download(dependency,basename(dependency))
        evalfile(basename(dependency))
    end

    install(dl_info...; prefix=prefix, force=true, verbose=verbose)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)
