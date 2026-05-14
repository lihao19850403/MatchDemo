import { HttpRequest, HttpResponse, HttpServer, NextFunction } from '@cxy/webserver';
import { socket } from '@kit.NetworkKit';
import { justReadRawFileSync, readRawFileResSync } from './common/filecenter/FileUtils';
import { GlobalContext } from './common/GlobalContext';
import fs from '@ohos.file.fs';

export class LocalWebServer {

  private static instance: LocalWebServer;

  private server: HttpServer;

  private serverResourcePath: string = '';

  public ip: string = '';

  public port: number = 8080;

  private constructor() {
    this.server = new HttpServer();
  }

  public static getInstance(): LocalWebServer {
    if (LocalWebServer.instance === undefined) {
      LocalWebServer.instance = new LocalWebServer();
    }
    return LocalWebServer.instance;
  }

  public start(): Promise<void> {
    return new Promise((resolve) => {
      this.server.startServer(this.port)
        .then((startInfo: socket.NetAddress) => {
          this.ip = startInfo.address;
          this.port = startInfo.port as number ?? 8080
          this.configuration();
          resolve();
        });
    });
  }

  public stop() {
    this.server.stopServer();
  }

  private configuration() {
    this.server.logger()
    this.server.cors(); // 支持跨域。
    this.server.auto(); //自动解析。
    this.serverResourcePath = GlobalContext.getContext()?.filesDir + '/www';
    this.server.registerStaticSite('/lesson', this.serverResourcePath, {
      index: ['index.html'],
      directoryListing: true
    });
    this.server.serveMultiSite(); // 启用多站点服务。
    this.server.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      res.setHeader('Cache-Control', 'no-cache');
      next();
    });

    this.prepareResource();
    this.prepareIndexFile();
  }

  private prepareResource() {
    try {
      // 创建资源目录。
      if (!fs.accessSync(this.serverResourcePath, fs.AccessModeType.EXIST)) {
        fs.mkdirSync(this.serverResourcePath);
      }
      // 写入normalizeCss。
      let normalCssFile = fs.openSync(this.serverResourcePath + '/normalize.css', fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let normalCssFileContent = justReadRawFileSync('classroom/styles/normalize.css');
      fs.writeSync(normalCssFile.fd, normalCssFileContent);
      fs.closeSync(normalCssFile);
      // 写入photoSphereViewerCss。
      let photoSphereViewerCssFile = fs.openSync(this.serverResourcePath + '/photo-sphere-viewer.core.index.min.css', fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let photoSphereViewerCssFileContent = justReadRawFileSync('classroom/styles/photo-sphere-viewer.core.index.min.css');
      fs.writeSync(photoSphereViewerCssFile.fd, photoSphereViewerCssFileContent);
      fs.closeSync(photoSphereViewerCssFile);
      // 写入threeCoreJs。
      let threeCoreJsFile = fs.openSync(this.serverResourcePath + '/three.core.js', fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let threeCoreJsFileContent = justReadRawFileSync('classroom/includes/three.core.js');
      fs.writeSync(threeCoreJsFile.fd, threeCoreJsFileContent);
      fs.closeSync(threeCoreJsFile);
      // 写入threeModuleJs。
      let threeModuleJsFile = fs.openSync(this.serverResourcePath + '/three.module.js', fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let threeModuleJsFileContent = justReadRawFileSync('classroom/includes/three.module.js');
      fs.writeSync(threeModuleJsFile.fd, threeModuleJsFileContent);
      fs.closeSync(threeModuleJsFile);
      // 写入photoSphereViewerJs。
      let photoSphereViewerJsFile = fs.openSync(this.serverResourcePath + '/photo-sphere-viewer.core.index.module.js', fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let photoSphereViewerJsContent = justReadRawFileSync('classroom/includes/photo-sphere-viewer.core.index.module.js');
      fs.writeSync(photoSphereViewerJsFile.fd, photoSphereViewerJsContent);
      fs.closeSync(photoSphereViewerJsFile);
      // 写入图片资源。
      ['伦敦-大本钟.jpg', '纽约海港.jpg'].forEach((picName: string) => {
        let demoFile = fs.openSync(this.serverResourcePath + '/' + picName, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        let demoFileContent = readRawFileResSync('classroom/lessons/' + picName);
        fs.writeSync(demoFile.fd, demoFileContent.buffer);
        fs.closeSync(demoFile);
      });
    } catch (error) {
    }
  }

  private prepareIndexFile() {
    try {
      let indexFileContent = `
<!doctype html>
<html lang="zh-cn">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <link rel="stylesheet" href="http://${this.ip}:${this.port}/lesson/normalize.css" />
    <link rel="stylesheet" href="http://${this.ip}:${this.port}/lesson/photo-sphere-viewer.core.index.min.css" />
</head>
<body>
<div id="viewer" style="width: 100vw; height: 100vh;"></div>
<script type="importmap">
    {
        "imports": {
            "three": "http://${this.ip}:${this.port}/lesson/three.module.js",
            "@photo-sphere-viewer/core": "http://${this.ip}:${this.port}/lesson/photo-sphere-viewer.core.index.module.js"
        }
    }
</script>

<script type="module">
    import { Viewer } from '@photo-sphere-viewer/core';

    function getParams() {
        var params = {};
        window.location.search.substring(1).split('&').forEach(function (param) {
            var pair = param.split('=');
            params[pair[0]] = decodeURIComponent(pair[1]);
        });
        return params;
    }

    const params = getParams();
    const picName = params['pic_name'];

    const viewer = new Viewer({
        container: document.querySelector('#viewer'),
        panorama: 'http://${this.ip}:${this.port}/lesson/' + picName + '.jpg',
        navbar: false
    });
</script>
</body>
</html>
      `;
      let indexFile = fs.openSync(this.serverResourcePath + '/index.html', fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(indexFile.fd, indexFileContent);
      fs.closeSync(indexFile);
    } catch (error) {
    }
  }
}