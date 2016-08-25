import vibe.d, std.algorithm, std.process, std.range, std.regex;
import travis : Travis;

string hookSecret;
string masterRepo;
Travis travis;

shared static this()
{
    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["0.0.0.0"];
    settings.options = HTTPServerOption.defaults & ~HTTPServerOption.parseJsonBody;
    readOption("port|p", &settings.port, "Sets the port used for serving.");

    auto router = new URLRouter;
    router
        .post("/github_hook", &githubHook)
        ;
    listenHTTP(settings, router);

    hookSecret = environment["GH_HOOK_SECRET"];
    travis = Travis("token " ~ environment["TRAVIS_TOKEN"]);
    masterRepo = environment["MASTER_REPO"];

    // workaround for stupid openssl.conf on Heroku
    HTTPClient.setTLSSetupCallback((ctx) {
        ctx.useTrustedCertificateFile("/etc/ssl/certs/ca-certificates.crt");
    });
    HTTPClient.setUserAgentString("dtour-bot vibe.d/"~vibeVersionString);
}

//==============================================================================
// Github hook
//==============================================================================

Json verifyRequest(string signature, string data)
{
    import std.digest.digest, std.digest.hmac, std.digest.sha;

    auto hmac = HMAC!SHA1(hookSecret.representation);
    hmac.put(data.representation);
    enforce(hmac.finish.toHexString!(LetterCase.lower) == signature.chompPrefix("sha1="),
            "Hook signature mismatch");
    return parseJsonString(data);
}

void githubHook(HTTPServerRequest req, HTTPServerResponse res)
{
    auto json = verifyRequest(req.headers["X-Hub-Signature"], req.bodyReader.readAllUTF8);
    if (req.headers["X-Github-Event"] == "ping")
        return res.writeBody("pong");
    if (req.headers["X-GitHub-Event"] != "pull_request")
        return res.writeVoidBody();

    auto action = json["action"].get!string;
    logDebug("#%s %s", json["number"], action);
    switch (action)
    {
    case "closed":
        if (json["pull_request"]["merged"].get!bool)
            action = "merged";
        goto case;
    case "opened", "reopened", "synchronize":
        auto repoSlug = json["pull_request"]["base"]["repo"]["full_name"].get!string;
        auto pullRequestURL = json["pull_request"]["html_url"].get!string;
        auto pullRequestNumber = json["pull_request"]["number"].get!uint;
        auto commitsURL = json["pull_request"]["commits_url"].get!string;
        auto commentsURL = json["pull_request"]["comments_url"].get!string;
        runTask(toDelegate(&handlePR), action, repoSlug, pullRequestURL, pullRequestNumber);
        return res.writeBody("handled");
    default:
        return res.writeBody("ignored");
    }
}

void handlePR(string action, string repoSlug, string pullRequestURL, uint pullRequestNumber)
{
    if (action == "merged")
    {
        travis.restart("merged", masterRepo);
    }
}
