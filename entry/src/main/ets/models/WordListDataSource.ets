import { LHBasicDataSource } from "./common/LHBaseDataSource";
import { WordItem } from "./WordItem";

/**
 * 单词列表数据源。
 * @author li.hao85
 */
export class WordListDataSource extends LHBasicDataSource<WordItem> {

  public pushData(data: WordItem) {
    this.dataArray.push(data);
    this.notifyDataAdded(this.dataArray.length - 1);
  }

  public cleanAll() {
    this.dataArray.splice(0);
    this.notifyMultipleDataDeleted(0, this.dataArray.length);
  }
}