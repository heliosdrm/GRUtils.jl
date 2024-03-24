using LibGit2, GRUtils

const srcpath = joinpath(dirname(pathof(GRUtils)), "..")
const docpath = joinpath(DEPOT_PATH[1], "localdocs/GRUtils")

function deploylatest()
    srcrepo = LibGit2.GitRepo(srcpath)
    docrepo = LibGit2.GitRepo(docpath)
    # 1. Check that the repos are not dirty and in the appropriate branches
    if LibGit2.isdirty(srcrepo)
        throw(ErrorException("Dirty source repository!"))
    elseif LibGit2.isdirty(docrepo)
        throw(ErrorException("Dirty docs repository!"))
    end
    src_head = LibGit2.head(srcrepo)
    doc_head = LibGit2.head(docrepo)
    if match(r"/heads/master$", LibGit2.name(src_head)) isa Nothing
        throw(ErrorException("Source repository should be in master branch"))
    elseif match(r"/heads/gh-pages$", LibGit2.name(doc_head)) isa Nothing
        throw(ErrorException("Docs repository should be in the branch gh-pages"))
    end
    # 2. Build docs and chek if it's ok
    include("make.jl")
    ask(prompt="") = (println(prompt); readline())
    okstr = ask("Is the build ok? (y/n): ")
    (isempty(okstr) || okstr[1] ≠ 'y') && throw(ErrorException("Deployment aborted"))
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

function deploytag(tagname, addlink=true)
    tagname = "v" * string(VersionNumber(tagname))
    srcrepo = LibGit2.GitRepo(srcpath)
    docrepo = LibGit2.GitRepo(docpath)
    srctarget = LibGit2.GitTag(srcrepo, tagname) |> LibGit2.target
    targetmsg = "Build from $(string(LibGit2.GitShortHash(srctarget, 7)))"
    # Look for the commit with the target message
    targetcommits = String[]
    lookup_msg = (oid, repo) -> begin
        msg = LibGit2.message(LibGit2.GitCommit(repo, string(oid)))
        # push!(targetcommits, msg)
        if msg == targetmsg
            push!(targetcommits, string(oid))
        end
    end
    LibGit2.with(LibGit2.GitRevWalker(docrepo)) do walker
        LibGit2.map(lookup_msg, walker)
    end
    isempty(targetcommits) && return nothing
    # The target commit exists ...
    targethash = targetcommits[1]
    baseref = LibGit2.lookup_branch(docrepo, "gh-pages")
    LibGit2.checkout!(docrepo, string(targethash))
    cp(joinpath(docpath, "latest"), joinpath(docpath, tagname), force=true)
    write(joinpath(docpath, tagname, "siteinfo.js"), """var DOCUMENTER_CURRENT_VERSION = "$tagname";""")
    LibGit2.branch!(docrepo, "gh-pages", string(LibGit2.GitHash(baseref)))
    # Add links if requested
    if addlink
        # Create symlink to the minor version
        linkname = joinpath(docpath, tagname[1:end-2])
        islink(linkname) && rm(linkname)
        symlink(tagname, joinpath(docpath, tagname[1:end-2]))
        # Update list of versions
        versionlist = readlines(joinpath(docpath, "versions.js"))
        minortag = tagname[1:end-2]
        newstable = true
        for line = 1:length(versionlist)
            m = match(r"(v\d+\.\d+)", versionlist[line])
            m == nothing && continue # skip line
            version = m.captures[1]
            if version == minortag  # the version is already in the list
                if newstable
                    rm(joinpath(docpath, "stable"))
                    symlink(tagname, joinpath(docpath, "stable"))
                end
                break
            end
            if VersionNumber(version) < VersionNumber(minortag)
                # Add the version
                insert!(versionlist, line, "  \"$minortag\",")
                write(joinpath(docpath, "versions.js"), join(versionlist, "\n"))
                if newstable
                    rm(joinpath(docpath, "stable"))
                    symlink(tagname, joinpath(docpath, "stable"))
                end
                break
            end
            newstable = false # there were higher versions released
        end
    end
    # Add and commit to gh-pages
    LibGit2.add!(docrepo, "*")
    commit = LibGit2.commit(docrepo, "Deploy $tagname")
    LibGit2.branch!(docrepo, "gh-pages", string(commit))
end

function bumpversion(oldversion, newversion)
    # Rename old version folder to new number
    oldtag = "v" * string(VersionNumber(oldversion))
    newtag = "v" * string(VersionNumber(newversion))
    mv(joinpath(docpath, oldtag), joinpath(docpath, newtag))
    write(joinpath(docpath, newtag, "siteinfo.js"), """var DOCUMENTER_CURRENT_VERSION = "$newtag";""")
    # Modify symlinks
    for file in readdir(docpath, join=true)
        if islink(file) && readlink(file) == oldtag
            rm(file)
            symlink(newtag, file)
        end
    end
    symlink(newtag, joinpath(docpath, oldtag))
    # Update list of versions
    versionlist = readlines(joinpath(docpath, "versions.js"))
    minortag = newtag[1:end-2]
    for line = 1:length(versionlist)
        m = match(r"(v\d+\.\d+)", versionlist[line])
        m == nothing && continue # skip line
        version = m.captures[1]
        if version == minortag  # the version is already in the list
            break
        end
        if VersionNumber(version) < VersionNumber(minortag)
            # Add the version
            insert!(versionlist, line, "  \"$minortag\",")
            write(joinpath(docpath, "versions.js"), join(versionlist, "\n"))
            break
        end
    end
end