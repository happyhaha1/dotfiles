const { shell } = require('electron')
const cp = require('child_process')

const items = [
    {
        title: "左",
        description: '将程序屏幕左移',
        match: 'zuo',
        cmd: `
        tell application "System Events"
            key code 123 using {control down, option down}
        end tell
        `
    },
    {
        title: "右",
        description: '将程序屏幕右移',
        match: 'you',
        cmd: `
        tell application "System Events"
            key code 124 using {control down, option down}
        end tell
        ` 
    },
    {
        title: "上",
        description: '将程序屏幕上移',
        match: 'shang',
        cmd: `
        tell application "System Events"
            key code 126 using {control down, option down}
        end tell
        ` 
    },
    {
        title: "下",
        description: '将程序屏幕下移',
        match: 'xia',
        cmd: `
        tell application "System Events"
            key code 125 using {control down, option down}
        end tell
        ` 
    },
    {
        title: "左下",
        description: '将程序屏幕左下移',
        match: 'zuoxia',
        cmd: `
        tell application "System Events"
            key code 38 using {control down, option down}
        end tell
        ` 
    },
    {
        title: "右下",
        description: '将程序屏幕右下移',
        match: 'youxia',
        cmd: `
        tell application "System Events"
            key code 40 using {control down, option down}
        end tell
        ` 
    },
    {
        title: "左上",
        description: '将程序屏幕左上移',
        match: 'zuoshang',
        cmd: `
        tell application "System Events"
            key code 32 using {control down, option down}
        end tell
        ` 
    },
    {
        title: "右上",
        description: '将程序屏幕右上移',
        match: 'youshang',
        cmd: `
        tell application "System Events"
            key code 34 using {control down, option down}
        end tell
        ` 
    },
    {
        title: "还原",
        description: '将程序屏幕还原',
        match: 'haiyuanreturn',
        cmd: `
        tell application "System Events"
            key code 51 using {control down, option down}
        end tell
        ` 
    },
    {
        title: "居中",
        description: '将程序屏幕居中',
        match: 'juzhong',
        cmd: `
        tell application "System Events"
            key code 8 using {control down, option down}
        end tell
        ` 
    },
    {
        title: "最大化",
        description: '将程序屏幕最大化',
        match: 'zuidahuabig',
        cmd: `
        tell application "System Events"
            key code 36 using {control down, option down}
        end tell
        ` 
    },
]

function tapKey(item) {
    window.utools.hideMainWindow()
    cp.exec(`osascript -e '${ item.cmd }'`,(error, stdout, stderr) => {
        if (error) return window.utools.showNotification(stderr)
        window.utools.outPlugin()
    })
}

window.exports = {
    'magent': {
        mode: 'list',
        args: {
            enter: (action, callbackSetList) => {
                callbackSetList(items)
            },
            search: (action, searchWord, callbackSetList) => {
                const searchItems = items.filter(x => x.title.toLowerCase().includes(searchWord)
                 || x.description.toLowerCase().includes(searchWord)
                 || x.match.toLowerCase().includes(searchWord))
                 callbackSetList(searchItems)
            },
            select: (action, itemData) => {
                tapKey(itemData)
            }
        }
    }
}