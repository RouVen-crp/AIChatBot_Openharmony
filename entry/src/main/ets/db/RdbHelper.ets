/*
 * Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd. & Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import relationalStore from '@ohos.data.relationalStore';
import { blockUi } from '../interfaces/blockUi';
import { Conversation } from '../model/MessageOption';
import Logger from '../utils/Logger';


const TAG: string = 'RdbHelper';
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'ChatDB.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const SQL_CREATE_CONVERSATION: string = `
CREATE TABLE IF NOT EXISTS conversations (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    lastMessage TEXT,
    timestamp INTEGER NOT NULL
)`;

const SQL_CREATE_MESSAGE: string = `
CREATE TABLE IF NOT EXISTS message (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  conversation_id INTEGER NOT NULL,
  role TEXT NOT NULL,
  content TEXT,
  think_content TEXT,
  think_time REAL,
  timestamp INTEGER NOT NULL,
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
)`;

export class RdbHelper {
  private rdbStore?: relationalStore.RdbStore = undefined;

  async openDatabase(context: Context): Promise<void> {
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      if (this.rdbStore === undefined) {
        Logger.error(TAG, 'Failed to create RdbStore');
        return;
      }
      await this.rdbStore.executeSql(SQL_CREATE_CONVERSATION);
      await this.rdbStore.executeSql(SQL_CREATE_MESSAGE);
      // 启用外键约束
      await this.rdbStore.executeSql('PRAGMA foreign_keys = ON;');
      Logger.info(TAG, 'Database opened successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to open database: ${error}`);
    }
  }

  async saveConversation(conversation: Conversation): Promise<boolean> {
    if (this.rdbStore === undefined) {
      Logger.error(TAG, 'RdbStore is not initialized');
      return false;
    }

    const values: relationalStore.ValuesBucket = {
      id: conversation.id,
      title: conversation.title,
      lastMessage: conversation.lastMessage,
      timestamp: conversation.timestamp.getTime(),
    };

    try {
      // 先检查是否存在这个会话
      const predicates = new relationalStore.RdbPredicates('conversations');
      predicates.equalTo('id', conversation.id);
      const exists = await this.rdbStore.query(predicates);
      let result: number;

      if (exists.rowCount > 0) {
        // 如果存在，使用UPDATE
        result = await this.rdbStore.update(values, predicates);
        Logger.info(TAG, `Updated conversation with id ${conversation.id}`);
      } else {
        // 如果不存在，使用INSERT
        result = await this.rdbStore.insert('conversations', values);
        Logger.info(TAG, `Inserted new conversation with id ${conversation.id}`);
      }
      exists.close();
      return result !== -1;
    } catch (error) {
      Logger.info(TAG, `Failed to save conversation: ${error}`);
      return false;
    }
  }

  async saveMessage(conversationId: number, message: blockUi): Promise<void> {
    if (this.rdbStore === undefined) {
      Logger.error(TAG, 'RdbStore is not initialized');
      return;
    }

    const values: relationalStore.ValuesBucket = {
      conversation_id: conversationId,
      role: message.role,
      content: message.content,
      think_content: message.thinkingContent as string,
      think_time: message.think_time as number,
      timestamp: Date.now()
    };

    try {
      await this.rdbStore.insert('message', values);
    } catch (error) {
      Logger.error(TAG, `Failed to save message: ${error}`);
    }
  }

  async getConversations(): Promise<Array<Conversation>> {
    if (this.rdbStore === undefined) {
      Logger.error(TAG, 'RdbStore is not initialized');
      return [];
    }

    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('conversations');
      predicates.orderByDesc('timestamp');
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates);

      const conversations: Array<Conversation> = [];
      Logger.info(TAG, `Found ${resultSet.rowCount} conversations`);

      while (resultSet.goToNextRow()) {
        const conversation: Conversation = {
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          title: resultSet.getString(resultSet.getColumnIndex('title')),
          lastMessage: resultSet.getString(resultSet.getColumnIndex('lastMessage')),
          timestamp: new Date(resultSet.getLong(resultSet.getColumnIndex('timestamp'))),
          msgArray: [],
          completionsParams: {
            model: "",
            stream: true,
            messages: []
          },
          is_started_progress: false
        }
        Logger.info(TAG, `Loaded conversation: ${JSON.stringify(conversation)}`);
        conversations.push(conversation);
      }
      resultSet.close();
      return conversations;
    } catch (error) {
      Logger.error(TAG, `Failed to get conversations: ${error}`);
      return [];
    }
  }

  async getMessages(conversationId: number): Promise<Array<blockUi>> {
    if (this.rdbStore === undefined) {
      Logger.error(TAG, 'RdbStore is not initialized');
      return [];
    }

    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('message');
      predicates.equalTo('conversation_id', conversationId).orderByAsc('timestamp');

      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates);
      const messages: Array<blockUi> = [];

      Logger.info(TAG, `Loading messages for conversation ${conversationId}`);

      while (resultSet.goToNextRow()) {
        const message: blockUi = new blockUi();
        message.content = resultSet.getString(resultSet.getColumnIndex('content'));
        message.role = resultSet.getString(resultSet.getColumnIndex('role'));
        message.thinkingContent = resultSet.getString(resultSet.getColumnIndex('think_content'));
        message.think_time = resultSet.getDouble(resultSet.getColumnIndex('think_time'));
        messages.push(message);
      }

      Logger.info(TAG, `Loaded ${messages.length} messages for conversation ${conversationId}`);

      resultSet.close();
      return messages;
    } catch (error) {
      Logger.error(TAG, `Failed to get messages: ${error}`);
      return [];
    }
  }

  async deleteConversation(conversationId: number): Promise<boolean> {
    if (this.rdbStore === undefined) {
      Logger.error(TAG, 'RdbStore is not initialized');
      return false;
    }

    try {
      // 删除该会话的所有消息
      const messagePredicates = new relationalStore.RdbPredicates('message');
      messagePredicates.equalTo('conversation_id', conversationId);
      await this.rdbStore.delete(messagePredicates);

      // 删除会话本身
      const conversationPredicates = new relationalStore.RdbPredicates('conversations');
      conversationPredicates.equalTo('id', conversationId);
      const deleteResult = await this.rdbStore.delete(conversationPredicates);

      Logger.info(TAG, `Successfully deleted conversation ${conversationId} and its messages`);
      return deleteResult > 0;

    } catch (error) {
      Logger.error(TAG, `Failed to delete conversation: ${error}`);
      return false;
    }
  }
}

export const rdbHelper: RdbHelper = new RdbHelper();