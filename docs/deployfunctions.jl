using LibGit2, GRUtils

const srcpath = joinpath(dirname(pathof(GRUtils)), "..")
const docpath = joinpath(DEPOT_PATH[1], "localdocs/GRUtils")

function deploylatest()
    srcrepo = LibGit2.GitRepo(srcpath)
    docrepo = LibGit2.GitRepo(docpath)
    # 1. Check that the repos are not dirty and in the appropriate branches
    if LibGit2.isdirty(srcrepo)
        @error "Dirty source repository!"
    elseif LibGit2.isdirty(docrepo)
        @error "Dirty docs repository!"
    end
    src_head = LibGit2.head(srcrepo)
    doc_head = LibGit2.head(docrepo)
    if match(r"/heads/master$", LibGit2.name(src_head)) isa Nothing
        @error "Source repository should be in master branch"
    elseif match(r"/heads/gh-pages$", LibGit2.name(doc_head)) isa Nothing
        @error "Docs repository should be in the branch gh-pages"
    end
    # 2. Build docs and chek if it's ok
    include("make.jl")
    ask(prompt="") = (println(prompt); readline())
    okstr = ask("Is the build ok? (y/n): ")
    (isempty(okstr) || okstr[1] ≠ 'y') && (@error "Deployment aborted")
    # 3. Create message for commit in doc repo
    head_commit = LibGit2.GitShortHash(LibGit2.GitHash(src_head), 7) |> string
    msg = "Build from $head_commit"
    # 4. Copy build in docs repo
    cp(joinpath(srcpath, "docs/build"), joinpath(docpath, "latest"), force=true)
    write(joinpath(docpath, "latest/siteinfo.js"), """var DOCUMENTER_CURRENT_VERSION = "latest";""")
    # 5. Add and commit to gh-pages
    LibGit2.add!(docrepo, "latest/*.*")
    commit = LibGit2.commit(docrepo, msg)
    LibGit2.branch!(docrepo, "gh-pages", string(commit))
end
