defmodule Conduit.Blog.Projectors.Article do
  use Commanded.Projections.Ecto,
    name: "Blog.Projectors.Article",
    consistency: :strong

  alias Conduit.Blog.Projections.{Article,Author,FavoritedArticle}
  alias Conduit.Blog.Events.{
    ArticleFavorited,
    ArticlePublished,
    ArticleUnfavorited,
    AuthorCreated,
  }
  alias Conduit.Repo

  project %AuthorCreated{} = author do
    Ecto.Multi.insert(multi, :author, %Author{
      uuid: author.author_uuid,
      user_uuid: author.user_uuid,
      username: author.username,
      bio: nil,
      image: nil,
    })
  end

  project %ArticlePublished{} = published, %{created_at: published_at} do
    multi
    |> Ecto.Multi.run(:author, fn _changes -> get_author(published.author_uuid) end)
    |> Ecto.Multi.run(:article, fn %{author: author} ->
      article = %Article{
        uuid: published.article_uuid,
        slug: published.slug,
        title: published.title,
        description: published.description,
        body: published.body,
        tags: published.tags,
        favorite_count: 0,
        published_at: published_at,
        author_uuid: author.uuid,
        author_username: author.username,
        author_bio: author.bio,
        author_image: author.image,
      }

      Repo.insert(article)
    end)
  end

  @doc """
  Favorite article for the user and update the article's favorite count
  """
  project %ArticleFavorited{article_uuid: article_uuid, favorited_by_author_uuid: favorited_by_author_uuid, favorite_count: favorite_count} do
    multi
    |> Ecto.Multi.run(:author, fn _changes -> get_author(favorited_by_author_uuid) end)
    |> Ecto.Multi.run(:favorited_article, fn %{author: author} ->
      favorite = %FavoritedArticle{
        article_uuid: article_uuid,
        favorited_by_author_uuid: favorited_by_author_uuid,
        favorited_by_username: author.username,
      }

      Repo.insert(favorite)
    end)
    |> Ecto.Multi.update_all(:article, article_query(article_uuid), set: [
      favorite_count: favorite_count,
    ])
  end

  @doc """
  Delete the user's favorite and update the article's favorite count
  """
  project %ArticleUnfavorited{article_uuid: article_uuid, unfavorited_by_author_uuid: unfavorited_by_author_uuid, favorite_count: favorite_count} do
    multi
    |> Ecto.Multi.delete_all(:favorited_article, favorited_article_query(article_uuid, unfavorited_by_author_uuid))
    |> Ecto.Multi.update_all(:article, article_query(article_uuid), set: [
      favorite_count: favorite_count,
    ])
  end

  defp get_author(uuid) do
    case Repo.get(Author, uuid) do
      nil -> {:error, :author_not_found}
      author -> {:ok, author}
    end
  end

  defp article_query(article_uuid) do
    from(a in Article, where: a.uuid == ^article_uuid)
  end

  defp favorited_article_query(article_uuid, author_uuid) do
    from(f in FavoritedArticle, where: f.article_uuid == ^article_uuid and f.favorited_by_author_uuid == ^author_uuid)
  end
end
