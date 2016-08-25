import vibe.d;
import std.range;

struct Travis
{
    string travisAuth;

    void restartBuild(size_t buildId)
    {
        auto url = "https://api.travis-ci.org/builds/%d/restart".format(buildId);
        requestHTTP(url, (scope req) {
            req.headers["Authorization"] = travisAuth;
            req.method = HTTPMethod.POST;
            req.headers["Accept"] = "application/vnd.travis-ci.2+json";
            ubyte[] r = cast(ubyte[]) "{}";
            req.writeBody(r);
        }, (scope res) {
            if (res.statusCode / 100 == 2)
                logInfo("Restarted Build %s\n", buildId);
            else
                logWarn("POST %s failed;  %s %s.\n%s", url, res.statusPhrase,
                    res.statusCode, res.bodyReader.readAllUTF8);
        });
    }

    void restart(string action, string repoSlug)
    {
        if (action != "synchronize" && action != "merged")
            return;

        auto url = "https://api.travis-ci.org/repos/%s/builds?event_type=push".format(repoSlug);
        auto activeBuildsForPR = requestHTTP(url, (scope req) {
                req.headers["Authorization"] = travisAuth;
                req.headers["Accept"] = "application/vnd.travis-ci.2+json";
            })
            .readJson["builds"][]
            //.filter!(b => b["pull_request_number"]);
            .take(1);

        restartBuild(activeBuildsForPR.front["id"].get!size_t);
    }
}
