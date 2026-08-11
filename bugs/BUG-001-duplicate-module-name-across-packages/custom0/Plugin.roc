import backends.Local
import commands.SplitCommand
import implementations.SplitLocal

Plugin := [].{
    plugin = {
        backend: Local.backend,
        command: SplitCommand.command,
        renderer: SplitLocal.renderer,
    }
}
