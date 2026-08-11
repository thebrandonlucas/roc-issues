import backends.Local
import commands.SplitCommand

SplitLocal := [].{
    renderer = |value| "${Local.backend.name}:${SplitCommand.command.name}:${value}"
}
