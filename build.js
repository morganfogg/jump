import nunjucks from "nunjucks";
import { writeFile, mkdir, copyFile } from "fs/promises";

const environments = [
    {
        name: 'regular',
        addCRLFCorrection: false,
        pathFromNativeConverter: undefined,
        pathToNativeConverter: undefined,
        note: (shell) => [
            `# NOTE: This particular version is intended for a regular ${shell.displayName} environment on *nix systems. If you are running a ${shell.displayName}`,
            `# environment on Windows (such as Git Bash, WSL or Cygwin), see instead either ${shell.folder}/wsl.sh or ${shell.folder}/cygwin.sh`,
        ].join('\n')
    },
    {
        name: 'wsl',
        addCRLFCorrection: true,
        pathFromNativeConverter: 'wslpath -u',
        pathToNativeConverter: 'wslpath -w',
        note: () => '# This version is designed for Windows Subsystem for Linux (WSL)',
    },
    {
        name: 'cygwin',
        addCRLFCorrection: true,
        pathFromNativeConverter: 'cygpath -u',
        pathToNativeConverter: 'cygpath -w',
        note: () => '# This version is designed for Cygwin-based environments including Git Bash and MSYS2',
    }
]

const shells = [
    {
        displayName: 'Bash/Zsh',
        folder: 'sh',
        extension: 'sh',
        template: './src/template.sh'
    },
    {
        displayName: 'Fish',
        folder: 'fish',
        extension: 'fish',
        template: './src/template.fish',
    },
]

async function main() {
    const templater = new nunjucks.Environment([
        new nunjucks.FileSystemLoader('.')
    ], {
        lstripBlocks: true,
        trimBlocks: true,
        autoescape: false,
    });

    for (let shell of shells) {
        await mkdir(`./${shell.folder}/`).catch(()=> {});

        for (let environment of environments) {
            environment = {...environment, note: environment.note(shell)};
            const result = templater.render(shell.template, environment);
            await writeFile(`./${shell.folder}/${environment.name}.${shell.extension}`, result);
        }
    }

    await copyFile('src/template.ps1', 'powershell/regular.ps1')
}

main();
