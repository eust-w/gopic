[🇨🇳](README_CN.md)[中文](README_CN.md)

# :tada: Introduction

gopic is an image hosting tool designed for uploading to services like Qiniu Cloud or GitHub. It is simple to use, easy to develop plugins for, fully concurrent, and highly decoupled.

# :zap: Usage

## Installation

### :scroll: Install from Source

```
bash复制代码$ git clone https://github.com/OSTGO/gopic/commits/main
$ cd gopic
$ ninja gopic
$ ls out/
```

The binary file will be generated in the `out` directory.

### :package: Download and Install

x86-64 Linux version: [gopic-linux-amd64](https://github.com/OSTGO/gopic/releases)

arm-64 Linux version: [gopic-linux-arm64](https://github.com/OSTGO/gopic/releases)

x86-64 macOS version: [gopic-mac-amd64](https://github.com/OSTGO/gopic/releases)

x86-64 Windows version: [gopic.exe](https://github.com/OSTGO/gopic/releases)

You can run the downloaded file directly. Note: Please run it via the command line!

## Interaction

| gopic Command | Description                                               |
| ------------- | --------------------------------------------------------- |
| init          | Initialize configuration, stored in `home/.gopic.json`    |
| conf          | Print configuration information, etc.                     |
| update        | Update from GitHub                                        |
| upload        | Main command for image hosting, detailed parameters below |
| convert       | Image conversion command                                  |

| gopic upload Parameter | Description                                                  | Default Value                                               |
| ---------------------- | ------------------------------------------------------------ | ----------------------------------------------------------- |
| -a, --all              | Boolean, if true, uploads to all active storage plugins      | false, if false and -s is empty, set to true                |
| -n, --name             | Boolean, if true, file names will not be hidden              | false                                                       |
| -f, --format           | String, selects which storage plugin to use for return value | Default is the first storage                                |
| -s, --storage          | String list, select which storage plugins to upload to, separated by `,` | Default is empty, if empty and -a not set, defaults to true |
| -p, --path             | String list, images can be local or network addresses        |                                                             |

Example: `gopic upload -a -p ./1.gif ./2.png https://pic.longtao.fun/pics/20210916/avatar.71pjc2scvak0.jpg -f qiniu`

This uploads `./1.gif ./2.png https://baidu.com/img.png` to all active plugins and uses the `qiniu` plugin's return value.

The result is:

```
ruby复制代码https://pic.longtao.fun/pics/22/8520716594215125117496217642356398137175_1.png
https://pic.longtao.fun/pics/22/230182152169544190214107228101001761655235_2.png
https://pic.longtao.fun/pics/22/254555454555441902154101556543454354543545_img.png
```

Here, `22` is the year, and the file name is a combination of the image's MD5 hash and the original file name, effectively preventing duplication.

| gopic convert Parameter | Description                                                  | Default Value                                         |
| ----------------------- | ------------------------------------------------------------ | ----------------------------------------------------- |
| -c, --convertPath       | String, folder or file to operate on                         | Current folder                                        |
| -a, --all               | Boolean, if true, uploads to all active storage plugins      | false, if false and -s is empty, will error           |
| -n, --name              | Boolean, if true, file names will not be hidden              | false                                                 |
| -r, --recurse           | Boolean, recursive replacement                               | Recursive by default (non-recursive not implemented)  |
| -s, --storage           | String list, select which storage plugins to upload to, separated by `,` | Default is empty, if empty and -a not set, will error |
| -f, --format            | String, selects which storage plugin to use for return value | Default is the first storage                          |
| -d, --dir               | String, output location after replacement                    | Required                                              |

Example: `./gopic-linux-amd64 convert -c /home/longtao/temp/blog/ -d /home/longtao/temp/blog2 -f samba -s samba`

This recursively converts all image links in markdown files under `/home/longtao/temp/blog/` to use the `samba` storage, and stores the converted markdown files in `/home/longtao/temp/blog2`.

Comparing `tree /home/longtao/temp/blog/` and `tree /home/longtao/temp/blog2`, they appear the same, but all images in the markdown files have been converted to use the `samba` storage.

![image-20220805150255551](https://pic.longtao.fun/pics/22/17699932065516729233109210501292428820286_image-20220805150255551.png)

## :seedling: Using with Typora

1. Go to `File -> Preferences` ![image-20220720161734836](https://pic.longtao.fun/pics/22/11820711612046216230142202241441926412985_image-20220720161734836.png)
2. In the `Preferences -> Image` tab, select to upload images when inserting them, and use `Custom Command` for the upload service. Fill in the required gopic command in the command field. ![image-20220720162157408](https://pic.longtao.fun/pics/22/111222126119019917210931716018085239178195_image-20220720162157408.png)
3. After verifying the image upload, you can happily paste images into your document, and the images will be automatically saved to the activated storage plugins. The images in this document were automatically processed using gopic.

# :heavy_plus_sign: Development

## Adding Plugins

Plugins should be added to the `plugin` directory and must meet the following criteria:

1. Define the plugin class, including the base class `*utils.BaseStorage`.
2. Implement the `Upload(im *utils.Image)(string, error)` method, which handles uploading a single image and returns the image URL and any error information.
3. Define an initialization function `init()`.
4. Write the plugin name and help documentation to `utils.StorageHelp`.
5. Write the plugin name and instance to `utils.StorageMap`, ensuring to check if it is `active`.

Example:

```
go复制代码package plugin

import (
    "bytes"
    "encoding/json"
    "gopic/conf"
    "gopic/utils"
    "io/ioutil"
    "net/http"
)

// Define plugin class
type GithubStorage struct {
   *utils.MetaStorage
}

// Define plugin name
const (
    githubPluginName = "github"
)

// Declare plugin configuration
var githubConfig map[string]interface{}

// Implement Upload method
func (g *GithubStorage) Upload(im *utils.Image) (string, error) {
    responseURL := githubConfig["responseurl"].(string)
    requestURL := githubConfig["requesturl"].(string)
    token := githubConfig["token"].(string)
    return responseURL + im.OutSuffix, uploadPictureToGithub(requestURL, token, im.OutBase64, im.OutSuffix)
}

// Implement plugin instance constructor
func NewGithubStorage() *GithubStorage {
    return &GithubStorage{utils.NewMetaStorage()}
}

// Specific implementation of upload, used to upload a single image
func uploadPictureToGithub(requestURL, token, data, suffix string) error {
    url := requestURL + suffix
    body := make(map[string]interface{})
    body["branch"] = "main"
    body["message"] = "markdown upload picture"
    body["content"] = data
    jsonBody, _ := json.Marshal(body)
    req, _ := http.NewRequest("PUT", url, bytes.NewBuffer(jsonBody))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "token " + token)
    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    _, err = ioutil.ReadAll(resp.Body)
    return err
}

// Initialization function
func init() {
    // Write help documentation
    utils.StorageHelp[githubPluginName] = githubHelp()
    // Read plugin configuration
    githubConfig = conf.Viper.GetStringMap(githubPluginName)
    // Check if plugin exists in configuration file
    if githubConfig == nil {
        return
    }
    // Check if plugin is active in configuration
    active := githubConfig["active"]
    if active == nil {
        return
    }
    // If plugin is active, add plugin instance to utils.StorageMap
    if active == true {
        utils.StorageMap[githubPluginName] = NewGithubStorage()
    }
}

// Help documentation specific implementation
func githubHelp() string {
    return "github plugin needs these parameters:\nactive: false or true\nresponseURL: like https://gcore.jsdelivr.net/gh/yourUserName/pics@main/\nrequestURL: like https://api.github.com/repos/yourUserName/pics/contents/\ntoken: your GitHub token"
}
```

## :bulb: Basic Framework

### Full Parallelism

All operations are fully parallel, both between different images and different plugins. Singleton Pattern: The same image is only processed once, saving memory and time, which is advantageous for large directories to enable fast conversion!

The time T11 for `using one plugin to transfer one image` and Tmn for `using m plugins to transfer n images`, under sufficient computational power, Tmn is far less than `T11*n`, and even more so compared to `T11*m*n`.

### High Decoupling

Plugins are fully decoupled from the framework, allowing for independent plugin development.