# frozen_string_literal: true
#
# app/models/concern配下に配置して、カーソルページネーションを実装したいモデルに以下を追加します。
#
#   include CursorPagination
#
# 🌟 id = 100 の直後のレコード(たぶん101)から後ろに5件取得
#
#   users, _ = User.paginate_by_cursor(
#     direction: :after,
#     limit: 5,
#     last_id: 100
#   )
#
# 🌟 id = 100 の直前のレコード(たぶん99)から前に20件取得
#
#   users, has_next_page = User.paginate_by_cursor(
#     direction: :before,
#     limit: 20,
#     last_id: 100
#   )
#
# 🌟 第一引数に仕掛かりのクエリオブジェクトを渡すこともできます。
#
#   users, has_next_page = User.paginate_by_cursor(
#     User.where(sms_auth_active: true),
#     direction: :before,
#     limit: 20,
#     last_id: 100
#   )
#
module CursorPagination
  extend ActiveSupport::Concern

  class_methods do
    def paginate_by_cursor(query = self, direction: :after, limit: 10, last_id: nil)
      query = apply_cursor_condition(query, direction.to_sym, last_id)
      records = query.limit(limit + 1).to_a
      has_next_page = records.size > limit
      records.pop if has_next_page
      [records, has_next_page]
    end

    private
      def apply_cursor_condition(query, direction, last_id)
        query = direction == :before ? query.order(id: :desc) : query.order(id: :asc)

        if last_id.nil?
          query
        elsif direction == :before
          query.where("id < ?", last_id)
        else # :after
          query.where("id > ?", last_id)
        end
      end
  end
end
