app [main!] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.0/F1JVZPYfWP71s8vk6tHcV1Qx1Ef6CZkwswGoCn8VHZmL.tar.zst",
}

import pf.OsStr
import pf.Path

require! = |root, relative| {
    path = relative.split_on("/").fold(root, Path.join)
    is_dir = Path.is_dir!(path)?
    if is_dir Ok({}) else Err(Missing(relative))
}

main! = |args|
    match args.drop_first(1).map(OsStr.display) {
        [text] => require!(Path.utf8(text), "")
        _ => Err(BadArgs)
    }
