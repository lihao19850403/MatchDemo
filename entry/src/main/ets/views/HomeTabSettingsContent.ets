import { LHAppSettingsTextSizePlanModel } from "../models/common/LHAppSettingsTextSizePlanModel";
import { openAlertDialog } from "../utils/common/DialogUtils";
import { ScreenObserver, ScreenStatusInfo } from "../utils/common/uiobserver/ScreenObserver";
import { getAppInfo, res2string } from "../utils/common/Utils";

/**
 * 首页 - 设置页 - 内容。
 * @author li.hao85
 */
@Component
export struct HomeTabSettingsContent {

  /** 应用文字字号方案。 */
  @Prop appTextSizePlan: LHAppSettingsTextSizePlanModel;

  /** 当前屏幕状态信息。 */
  private screenStatus: ScreenStatusInfo | undefined = undefined;

  aboutToAppear(): void {
    ScreenObserver.subscribe(this.getUIContext(), (screenStatus: ScreenStatusInfo) => {
      this.screenStatus = screenStatus;
    });
  }

  aboutToDisappear(): void {
    ScreenObserver.unsubscribe(this.getUIContext());
  }

  build() {
    Scroll() {
      Column() {
        Blank()
          .width('100%')
          .height(50)
          .flexGrow(1)
        Image($r('app.media.app_icon_start'))
          .width('512px')
          .height('512px')
          .objectFit(ImageFit.Contain)
        Blank()
          .width('100%')
          .height(30)
          .flexShrink(1)
        Text(`${res2string($r('app.string.app_name'))}\nV${getAppInfo().versionName}`)
          .textAlign(TextAlign.Center)
        Blank()
          .width('100%')
          .height(30)
          .flexShrink(1)
        Column({ space: 4 }) {
          this.InfoBanner($r('app.string.home_tab_settings_about_us'), $r('app.string.home_tab_settings_about_us_content'))
          this.InfoBanner($r('app.string.home_tab_settings_about_software'), $r('app.string.home_tab_settings_about_software_content'))
        }
        Blank()
          .width('100%')
          .height(50)
          .flexGrow(1)
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding(8)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .flexShrink(1)
  }

  @Builder
  private InfoBanner(bannerName: ResourceStr, content: ResourceStr) {
    Button() {
      Row() {
        Text(bannerName)
          .fontSize(this.appTextSizePlan.unifiedDialogContentTextSize)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .padding(8)
    }
    .borderRadius(4)
    .backgroundColor(Color.White)
    .onClick(() => openAlertDialog({
      title: bannerName,
      content: content,
      contentAlign: TextAlign.Start,
      confirmAction: () => {}
    }))
  }
}